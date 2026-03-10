#Requires -Version 5.1
<#
.SYNOPSIS
    de-claw — OpenClaw full uninstall script (Windows / WSL2)

.DESCRIPTION
    Completely remove OpenClaw and all related components from Windows.
    Supports: native Windows 10/11, and Linux environments inside WSL2.

    Note: OpenClaw is officially recommended to run inside WSL2.
    If you installed OpenClaw in WSL2, this script can automatically call the Linux purge.sh.

.PARAMETER DryRun
    Preview mode, only shows what would be deleted, makes no changes.

.PARAMETER Yes
    Skip all confirmation prompts.

.PARAMETER Backup
    Backup workspace data to the specified directory (Desktop by default).

.PARAMETER NoBackup
    Skip backup prompts and delete data directly.

.PARAMETER KeepSkills
    Keep Skills directories.

.EXAMPLE
    .\purge.ps1 -DryRun
    .\purge.ps1 -Yes -NoBackup
    .\purge.ps1 -Backup "$env:USERPROFILE\Desktop"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun,
    [switch]$Yes,
    [string]$Backup = "",
    [switch]$NoBackup,
    [switch]$KeepSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ─── Color helpers ─────────────────────────────────────────────────────────────
function Write-Section { param([string]$Text)
    Write-Host "`n" -NoNewline
    Write-Host "▶ $Text" -ForegroundColor Cyan -NoNewline
    Write-Host "" }
function Write-Ok     { param([string]$Text) Write-Host "  ✓ $Text" -ForegroundColor Green }
function Write-Skip   { param([string]$Text) Write-Host "  ✗ Skipped: $Text" -ForegroundColor DarkGray }
function Write-Warn   { param([string]$Text) Write-Host "  ⚠ $Text" -ForegroundColor Yellow }
function Write-Info   { param([string]$Text) Write-Host "  ℹ $Text" -ForegroundColor Blue }
function Write-Found  { param([string]$Text) Write-Host "  ● $Text" -ForegroundColor Green }
function Write-Missing{ param([string]$Text) Write-Host "  ○ (not found) $Text" -ForegroundColor DarkGray }
function Write-DryRun { param([string]$Text) Write-Host "  → [DRY-RUN] $Text" -ForegroundColor Magenta }

$script:RemovedCount = 0
$script:SkippedCount = 0

function Remove-IfExists {
    param([string]$Path, [string]$Label = "")
    $displayLabel = if ($Label) { $Label } else { $Path }
    if (Test-Path $Path) {
        if ($DryRun) {
            Write-DryRun "Would remove: $Path"
        } else {
            Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
            Write-Ok "Removed: $displayLabel"
        }
        $script:RemovedCount++
    } else {
        Write-Skip $displayLabel
        $script:SkippedCount++
    }
}

function Invoke-Cmd {
    param([string]$Desc, [scriptblock]$Cmd)
    if ($DryRun) {
        Write-DryRun "Would run: $Desc"
    } else {
        try {
            & $Cmd
            Write-Ok $Desc
        } catch {
            Write-Warn "$Desc (ignored error: $_)"
        }
    }
}

function Confirm-Action {
    param([string]$Prompt, [bool]$DefaultYes = $false)
    if ($Yes) { return $true }
    $hint = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    Write-Host "`n$Prompt $hint " -ForegroundColor Yellow -NoNewline
    $answer = Read-Host
    if ($DefaultYes) { return $answer -notmatch "^[Nn]" }
    return $answer -match "^[Yy]"
}

function Get-RandomClawPhrase {
    $phrases = @(
        "no claw, no law, just rm -rf",
        "one does not simply de-claw prod",
        "let the claws go silent",
        "this is how the claw ends",
        "bye bye claw, hello clean slate"
    )
    return Get-Random -InputObject $phrases
}

# ─── Banner ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "   ██████╗ ███████╗      ██████╗██╗      █████╗ ██╗    ██╗" -ForegroundColor Red
Write-Host "   ██╔══██╗██╔════╝     ██╔════╝██║     ██╔══██╗██║    ██║" -ForegroundColor Red
Write-Host "   ██║  ██║█████╗  ─── ██║     ██║     ███████║██║ █╗ ██║" -ForegroundColor Red
Write-Host "   ██║  ██║██╔══╝      ██║     ██║     ██╔══██║██║███╗██║" -ForegroundColor Red
Write-Host "   ██████╔╝███████╗    ╚██████╗███████╗██║  ██║╚███╔███╔╝" -ForegroundColor Red
Write-Host "   ╚═════╝ ╚══════╝     ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝" -ForegroundColor Red
Write-Host ""
Write-Host "  de-claw — OpenClaw full uninstall tool v1.1 (Windows)" -ForegroundColor White
Write-Host "  Windows 10/11 · WSL2 | supports OpenClaw 2026.x" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  User: $env:USERNAME  |  Home: $env:USERPROFILE" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "  ⚡ DRY-RUN mode: preview only, no changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# ─── Detect WSL2 ──────────────────────────────────────────────────────────────
$WslAvailable = $false
$WslDistros = @()
try {
    $wslList = & wsl --list --quiet 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslList) {
        $WslAvailable = $true
        $WslDistros = $wslList | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() -replace '\x00', '' }
    }
} catch {}

# ─── Scan for installation footprints ────────────────────────────────────────
Write-Host "  Scanning for OpenClaw footprints..." -ForegroundColor White
Write-Host ""

$FoundCount = 0

function Check-Exists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Write-Found $Label
        $script:FoundCount++
    } else {
        Write-Missing $Label
    }
}

# Task Scheduler
$TaskExists = $false
try {
    $task = Get-ScheduledTask -TaskName "OpenClaw Gateway" -ErrorAction SilentlyContinue
    if ($task) { Write-Found "Scheduled task: OpenClaw Gateway"; $FoundCount++; $TaskExists = $true }
    else { Write-Missing "Scheduled task: OpenClaw Gateway" }
} catch { Write-Missing "Scheduled task: OpenClaw Gateway" }

# Global npm package
$NpmRoot = try { (npm root -g 2>$null) } catch { "" }
if ($NpmRoot -and (Test-Path "$NpmRoot\openclaw")) {
    Write-Found "npm global package: $NpmRoot\openclaw"
    $FoundCount++
} else {
    Write-Missing "npm global package: openclaw"
}

# Common npm binary locations
foreach ($npmBin in @("$env:APPDATA\npm\openclaw.cmd", "$env:APPDATA\npm\openclaw")) {
    if (Test-Path $npmBin) { Write-Found "npm binary: $npmBin"; $FoundCount++ }
}

# AppData directories
foreach ($dir in @("OpenClaw", "clawdbot", "clawdis", "clawhub")) {
    Check-Exists "$env:APPDATA\$dir" "AppData\Roaming\$dir"
    Check-Exists "$env:LOCALAPPDATA\$dir" "AppData\Local\$dir"
}

# User data directory
Check-Exists "$env:USERPROFILE\.openclaw" "~\.openclaw (workspaces/credentials/logs)"

# Cursor MCP cache
Get-Item "$env:USERPROFILE\.cursor\projects\*openclaw*" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Found "Cursor MCP cache: $($_.Name)"
    $FoundCount++
}

# Registry
foreach ($regPath in @("HKCU:\Software\OpenClaw", "HKCU:\Software\ai.openclaw")) {
    if (Test-Path $regPath) { Write-Found "Registry: $regPath"; $FoundCount++ }
    else { Write-Missing "Registry: $regPath" }
}

# OpenClaw inside WSL2
if ($WslAvailable) {
    Write-Host ""
    Write-Host "  WSL2 detected; OpenClaw may also be installed inside these distros:" -ForegroundColor Yellow
    foreach ($distro in $WslDistros) {
        $ocExists = & wsl -d $distro -- test -e ~/.openclaw 2>$null; $code = $LASTEXITCODE
        if ($code -eq 0) {
            Write-Found "  WSL2[$distro]: ~/.openclaw"
            $FoundCount++
        }
    }
}

Write-Host ""
Write-Host "  Found $FoundCount installation footprints" -ForegroundColor White

if ($FoundCount -eq 0) {
    Write-Host "`n  OpenClaw does not appear to be installed (or is already fully removed)." -ForegroundColor Green
    exit 0
}

# ─── Prefer cleaning WSL2 first (if present) ─────────────────────────────────
if ($WslAvailable -and $WslDistros.Count -gt 0) {
    Write-Host ""
    Write-Host "  OpenClaw is best run in WSL2." -ForegroundColor Yellow
    Write-Host "  Recommended: run purge.sh inside WSL2 to clean Linux parts," -ForegroundColor DarkGray
    Write-Host "  then let this script clean Windows side leftovers (tasks, registry, etc.)." -ForegroundColor DarkGray

    if (Confirm-Action "  Automatically run purge.sh in the default WSL2 distro?") {
        $skillPath = "~/.cursor/skills/de-claw/scripts/purge.sh"
        $wslArgs = @()
        if ($DryRun) { $wslArgs += "--dry-run" }
        if ($Yes) { $wslArgs += "--yes" }
        if ($NoBackup) { $wslArgs += "--no-backup" }
        if ($KeepSkills) { $wslArgs += "--keep-skills" }

        $wslCmd = "bash $skillPath $($wslArgs -join ' ') 2>&1 || true"
        Write-Info "Running inside WSL2: $wslCmd"

        if (-not $DryRun) {
            & wsl -- bash -c $wslCmd
        }
        Write-Host ""
        Write-Host "  WSL2 cleanup complete, continuing with Windows side..." -ForegroundColor Cyan
    }
}

# ─── Backup options ───────────────────────────────────────────────────────────
$backupFile = ""
if ((Test-Path "$env:USERPROFILE\.openclaw") -and (-not $NoBackup)) {
    $dataSize = try {
        $size = (Get-ChildItem "$env:USERPROFILE\.openclaw" -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        "{0:N0} MB" -f ($size / 1MB)
    } catch { "unknown size" }

    Write-Host ""
    Write-Host "  Workspace data directory: ~\.openclaw ($dataSize)" -ForegroundColor White
    Write-Host "  Contains: workspaces, API keys, conversation history, custom config" -ForegroundColor DarkGray

    if (-not $Backup) {
        if (Confirm-Action "  Backup workspace data before deleting? (strongly recommended)" $true) {
            $defaultBackup = if (Test-Path "$env:USERPROFILE\Desktop") { "$env:USERPROFILE\Desktop" } else { $env:USERPROFILE }
            if (-not $Yes) {
                Write-Host "  Save backup to [$defaultBackup]: " -ForegroundColor Yellow -NoNewline
                $userInput = Read-Host
                $Backup = if ($userInput.Trim()) { $userInput.Trim() } else { $defaultBackup }
            } else {
                $Backup = $defaultBackup
            }
        }
    }

    if ($Backup) {
        if (-not (Test-Path $Backup)) {
            New-Item -ItemType Directory -Path $Backup -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = "$Backup\openclaw-backup-$timestamp.zip"

        if ($DryRun) {
            Write-DryRun "Would backup ~\.openclaw to: $backupFile"
        } else {
            Write-Host "  Creating backup..." -NoNewline
            try {
                Compress-Archive -Path "$env:USERPROFILE\.openclaw" -DestinationPath $backupFile -Force
                $backupSize = (Get-Item $backupFile).Length / 1MB
                Write-Host ("`r  ✓ Backup created: {0} ({1:N1} MB)" -f $backupFile, $backupSize) -ForegroundColor Green
            } catch {
                Write-Host ""
                Write-Warn "Backup failed: $_"
                if (-not (Confirm-Action "  Continue uninstall without backup?")) {
                    Write-Host "Cancelled."; exit 0
                }
            }
        }
    }
}

# ─── Final confirmation ───────────────────────────────────────────────────────
if (-not (Confirm-Action "Proceed with uninstalling OpenClaw? This action is IRREVERSIBLE.")) {
    Write-Host "`n  Uninstall cancelled." -ForegroundColor Yellow
    exit 0
}

if (-not $DryRun) {
    # Extra safety: random phrase confirmation to avoid accidental destructive runs
    $clawPhrase = Get-RandomClawPhrase
    Write-Host ""
    Write-Host "  Type the following phrase exactly to confirm irreversible uninstall:" -ForegroundColor Yellow
    Write-Host "    $clawPhrase" -ForegroundColor White
    Write-Host ""
    $typed = Read-Host "  Confirm phrase"
    if ($typed -ne $clawPhrase) {
        Write-Host "`n  Phrase mismatch, uninstall aborted." -ForegroundColor Yellow
        exit 0
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 1: stop running OpenClaw processes
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Stopping OpenClaw processes"

$processes = @()
try {
    $processes = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "openclaw|OpenClaw|clawdbot|clawhub|clawdis" }
} catch {}

if ($processes.Count -gt 0) {
    foreach ($proc in $processes) {
        if ($DryRun) {
            Write-DryRun ("Would stop process: {0} (PID {1})" -f $proc.Name, $proc.Id)
        } else {
            try {
                $proc | Stop-Process -Force
                Write-Ok ("Stopped: {0} (PID {1})" -f $proc.Name, $proc.Id)
            } catch {
                Write-Warn ("Could not stop {0}: {1}" -f $proc.Name, $_)
            }
        }
    }
} else {
    Write-Skip "No running OpenClaw processes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 2: delete Task Scheduler entries
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Deleting Task Scheduler tasks"

foreach ($taskName in @("OpenClaw Gateway", "openclaw", "OpenClaw")) {
    try {
        $t = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($t) {
            if ($DryRun) {
                Write-DryRun "Would delete scheduled task: $taskName"
            } else {
                Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                Write-Ok "Deleted scheduled task: $taskName"
            }
            $script:RemovedCount++
        } else {
            Write-Skip "Scheduled task does not exist: $taskName"
            $script:SkippedCount++
        }
    } catch {
        Write-Warn "Error while handling scheduled task $taskName: $_"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 3: uninstall global npm package
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Uninstalling global npm package"

$npmAvailable = $null -ne (Get-Command npm -ErrorAction SilentlyContinue)

if ($npmAvailable) {
    $isInstalled = (npm list -g --depth=0 2>$null) -match "openclaw"
    if ($isInstalled) {
        Invoke-Cmd "npm uninstall -g openclaw" { npm uninstall -g openclaw 2>$null }
    } else {
        Write-Skip "npm global package openclaw"
    }
} else {
    Write-Warn "npm not found, will try deleting files directly"
}

# Fallback: delete directory directly
$npmRootPaths = @(
    (try { npm root -g 2>$null } catch { "" }),
    "$env:APPDATA\npm\node_modules",
    "$env:ROAMING\npm\node_modules"
) | Where-Object { $_ }

foreach ($npmRootPath in $npmRootPaths) {
    Remove-IfExists "$npmRootPath\openclaw" "npm package: $npmRootPath\openclaw"
}

# Delete binaries
foreach ($bin in @("$env:APPDATA\npm\openclaw.cmd", "$env:APPDATA\npm\openclaw",
                    "$env:APPDATA\npm\openclaw.ps1")) {
    Remove-IfExists $bin ("npm binary: {0}" -f (Split-Path $bin -Leaf))
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 4: clean AppData directories
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Cleaning AppData directories"

foreach ($dir in @("OpenClaw", "clawdbot", "clawdis", "clawhub")) {
    Remove-IfExists "$env:APPDATA\$dir"      "AppData\Roaming\$dir"
    Remove-IfExists "$env:LOCALAPPDATA\$dir" "AppData\Local\$dir"
}

# Program installation directories (if GUI installer was used)
foreach ($progDir in @(
    "$env:LOCALAPPDATA\Programs\OpenClaw",
    "$env:PROGRAMFILES\OpenClaw",
    "${env:PROGRAMFILES(X86)}\OpenClaw"
)) {
    Remove-IfExists $progDir ("Program directory: {0}" -f (Split-Path $progDir -Leaf))
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 5: delete registry keys
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Cleaning registry entries"

foreach ($regPath in @(
    "HKCU:\Software\OpenClaw",
    "HKCU:\Software\ai.openclaw",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenClaw"
)) {
    if (Test-Path $regPath) {
        if ($DryRun) {
            Write-DryRun "Would delete registry key: $regPath"
        } else {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Deleted registry key: $regPath"
        }
        $script:RemovedCount++
    } else {
        Write-Skip "Registry key: $regPath"
        $script:SkippedCount++
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 6: clean PATH environment variable
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Cleaning PATH environment variable"

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$clawPaths = $userPath -split ";" | Where-Object { $_ -match "openclaw" -or $_ -match "OpenClaw" }
if ($clawPaths.Count -gt 0) {
    $newPath = ($userPath -split ";" | Where-Object { $_ -notmatch "openclaw" -and $_ -notmatch "OpenClaw" }) -join ";"
    if ($DryRun) {
        Write-DryRun ("Would remove from PATH: {0}" -f ($clawPaths -join '; '))
    } else {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Ok "Removed OpenClaw-related paths from user PATH"
    }
    $script:RemovedCount++
} else {
    Write-Skip "No OpenClaw-related entries in PATH"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 7: delete ~/.openclaw data directory
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Removing data directory"

$dataDir = "$env:USERPROFILE\.openclaw"
if (Test-Path $dataDir) {
    if ($Backup -or $NoBackup) {
        Remove-IfExists $dataDir "~\.openclaw (workspaces/credentials/logs)"
    } else {
        if (Confirm-Action "  Final confirmation: permanently delete ~\.openclaw?") {
            Remove-IfExists $dataDir "~\.openclaw (workspaces/credentials/logs)"
        } else {
            Write-Warn "Skipped ~\.openclaw (user chose to keep it)"
        }
    }
} else {
    Write-Skip "~\.openclaw does not exist"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Step 8: clean Cursor / MCP integration
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Cleaning Cursor / IDE integration"

Get-Item "$env:USERPROFILE\.cursor\projects\*openclaw*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-IfExists $_.FullName ("Cursor MCP cache: {0}" -f $_.Name) }

Get-Item "$env:USERPROFILE\.cursor\extensions\*openclaw*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-IfExists $_.FullName ("Cursor extension: {0}" -f $_.Name) }

# ═══════════════════════════════════════════════════════════════════════════════
# Step 9: clean temporary files
# ═══════════════════════════════════════════════════════════════════════════════
Write-Section "Cleaning temporary files"

Get-Item "$env:TEMP\openclaw*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-IfExists $_.FullName ("Temporary file: {0}" -f $_.Name) }
Get-Item "$env:TEMP\claw*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-IfExists $_.FullName ("Temporary file: {0}" -f $_.Name) }

# ═══════════════════════════════════════════════════════════════════════════════
# Step 10: Skills directories (optional)
# ═══════════════════════════════════════════════════════════════════════════════
if (-not $KeepSkills) {
    Write-Section "Cleaning Skills directories (optional)"
    Write-Warn "These directories may contain your own unrelated Skills"

    $skillsDir = "$env:USERPROFILE\.cursor\skills"
    if (Test-Path $skillsDir) {
        if (Confirm-Action "  Delete ~\.cursor\skills (all personal Skills)?") {
            Remove-IfExists $skillsDir "~\.cursor\skills"
        } else {
            Write-Warn "Skipped ~\.cursor\skills"
        }
    } else {
        Write-Skip "~\.cursor\skills does not exist"
    }

    $agentsSkills = "$env:USERPROFILE\.agents\skills"
    if (Test-Path $agentsSkills) {
        if (Confirm-Action "  Delete ~\.agents\skills (Agents Skills)?") {
            Remove-IfExists $agentsSkills "~\.agents\skills"
        } else {
            Write-Warn "Skipped ~\.agents\skills"
        }
    } else {
        Write-Skip "~\.agents\skills does not exist"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Final summary
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host ("━" * 62) -ForegroundColor Green
if ($DryRun) {
    Write-Host "  [DRY-RUN] Preview completed" -ForegroundColor Yellow
    Write-Host "  Would delete $($script:RemovedCount) items, $($script:SkippedCount) not found/skipped" -ForegroundColor Yellow
    Write-Host "  Re-run without -DryRun to actually uninstall." -ForegroundColor DarkGray
} else {
    Write-Host "  ✅ de-claw complete!" -ForegroundColor Green
    Write-Host "  Deleted $($script:RemovedCount) items, $($script:SkippedCount) not found/skipped" -ForegroundColor Green
    if ($backupFile) { Write-Host "  Backup saved at: $backupFile" -ForegroundColor Green }
    Write-Host ""
    Write-Host "  Recommended next steps:" -ForegroundColor DarkGray
    Write-Host "  1. Restart PowerShell/CMD to refresh PATH" -ForegroundColor DarkGray
    Write-Host "  2. If you no longer need this helper, delete: ~\.cursor\skills\de-claw" -ForegroundColor DarkGray
}
Write-Host ("━" * 62) -ForegroundColor Green
