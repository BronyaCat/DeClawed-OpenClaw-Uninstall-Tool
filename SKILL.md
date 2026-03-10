---
name: de-claw
description: Completely uninstall OpenClaw from macOS, Linux servers, or Windows (including WSL2), removing services/daemons, npm packages, apps, data directories, preferences, shell RC entries, Cursor caches, etc. Use this Skill when the user asks to "uninstall OpenClaw", "remove OpenClaw", "clean OpenClaw", "let OpenClaw delete itself", "de-claw", or "fully remove OpenClaw". Always run a dry-run preview first and ask for confirmation before making destructive changes. Supports backing up workspace data.
---

# de-claw — OpenClaw self-uninstall Skill

> **Two ways to use it**
> - **Skill mode** (this file): OpenClaw is running; the Agent orchestrates the full uninstall flow
> - **Script mode**: OpenClaw is broken or cannot start; the user runs the scripts directly

---

## Mode 1: Skill mode (Agent-driven)

When OpenClaw can still start normally, the Agent should follow this flow:

### Flow

**Step 1: Detect platform**

```bash
uname -s   # macOS → Darwin, Linux/WSL2 → Linux
```

Choose the script based on the result:
- macOS / Linux / WSL2 → `~/.cursor/skills/de-claw/scripts/purge.sh`
- Windows (PowerShell) → `~/.cursor/skills/de-claw/scripts/purge.ps1`

**Step 2: Dry-run (must run first)**

macOS / Linux:
```bash
bash ~/.cursor/skills/de-claw/scripts/purge.sh --dry-run
```

Windows (PowerShell):
```powershell
~\.cursor\skills\de-claw\scripts\purge.ps1 -DryRun
```

Show the full dry-run output to the user and get explicit confirmation.

**Step 3: Ask about backup**

Explain that `~/.openclaw` contains all workspaces, API keys, and conversation history.
Offer options:
- Backup to Desktop (default): add `--backup ~/Desktop`
- Backup to a custom path: add `--backup <path>`
- No backup: add `--no-backup`

**Step 4: Execute uninstall**

Compose commands based on the user’s choice:

| Scenario | Command |
|---------|---------|
| Backup to Desktop + uninstall | `purge.sh --backup ~/Desktop` |
| No backup + keep Skills | `purge.sh --no-backup --keep-skills` |
| Fully non-interactive uninstall | `purge.sh --yes --no-backup` |

**Step 5: Clean up the Skill itself (optional)**

After uninstall completes, suggest:
```bash
rm -rf ~/.cursor/skills/de-claw
```
Windows: `Remove-Item -Recurse -Force ~\.cursor\skills\de-claw`

---

## Mode 2: Script mode (OpenClaw is broken)

When OpenClaw cannot start, the user can run the scripts directly.
Tell the user:

### macOS / Linux

```bash
# 1. Locate the script (if OpenClaw is installed but broken)
ls ~/.cursor/skills/de-claw/scripts/

# 2. Dry-run (safe: does not delete anything)
bash ~/.cursor/skills/de-claw/scripts/purge.sh --dry-run

# 3. Execute with backup to Desktop
bash ~/.cursor/skills/de-claw/scripts/purge.sh --backup ~/Desktop

# If ~/.cursor/skills/de-claw is also missing, download the script:
# curl -fsSL https://raw.githubusercontent.com/... | bash -s -- --dry-run
```

### Windows (PowerShell)

```powershell
# 1. Allow local scripts (if needed)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 2. Dry-run
~\.cursor\skills\de-claw\scripts\purge.ps1 -DryRun

# 3. Execute with backup to Desktop
~\.cursor\skills\de-claw\scripts\purge.ps1 -Backup "$env:USERPROFILE\Desktop"
```

---

## Parameter reference

### purge.sh (macOS / Linux)

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview only, do not actually delete |
| `--yes` / `-y` | Skip all interactive confirmations |
| `--backup [dir]` | Backup workspace to directory (default `~/Desktop`) |
| `--no-backup` | Skip backup prompts and delete directly |
| `--keep-skills` | Keep the Skills directories |

### purge.ps1 (Windows)

| Flag | Description |
|------|-------------|
| `-DryRun` | Preview only, do not actually delete |
| `-Yes` | Skip all interactive confirmations |
| `-Backup [dir]` | Backup workspace data |
| `-NoBackup` | Skip backup and delete directly |
| `-KeepSkills` | Keep the Skills directories |

---

## Cleanup scope (all platforms)

```
✅ macOS
  LaunchAgent:     ~/Library/LaunchAgents/ai.openclaw.gateway.plist
  npm global pkg:  /opt/homebrew/lib/node_modules/openclaw/
  Application:     /Applications/OpenClaw.app
  Application Support: OpenClaw/ clawdbot/ clawdis/ clawhub/
  Preferences:     ai.openclaw.mac.plist  ai.openclaw.shared.plist
  Keychain:        openclaw credential entries

✅ Linux / WSL2
  systemd services: openclaw-gateway.service (user + system)
  npm global pkg:   $(npm root -g)/openclaw/
  XDG data:         ~/.config/{OpenClaw,clawdbot,clawdis,clawhub}/

✅ Windows
  Scheduled task:   "OpenClaw Gateway"
  npm global pkg:   %APPDATA%\npm\node_modules\openclaw\
  AppData:          %APPDATA%\{OpenClaw,clawdbot,clawdis,clawhub}\
  Registry:         HKCU:\Software\OpenClaw
  PATH:             OpenClaw entries in the user PATH

✅ Cross‑platform
  Data dir:         ~/.openclaw/ (can be backed up before deletion)
  Shell RC:         .bashrc .bash_profile .zshrc .profile .fish
  Cursor cache:     ~/.cursor/projects/*openclaw*/
  Temp files:       /tmp/openclaw*
  Processes:        running openclaw processes (kill before delete)
  Skills (optional): ~/.cursor/skills/ ~/.agents/skills/
```
