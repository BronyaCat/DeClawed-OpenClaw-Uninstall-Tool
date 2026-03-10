<div align="center">

### 🌐 Language

**English** · [简体中文](README_zh-CN.md)

---

# ✂️ DeClawed

**OpenClaw Uninstall Tool**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/pulls)

</div>

---

> **OpenClaw says:** The AI that actually does things.  
> **DeClawed says:** The one that actually puts the 🦞 back in the pot.

When you're done and want it gone, DeClawed **uninstalls OpenClaw** from your machine—the app, its service, config, and data. One command. No clone, no manual steps.  
**Note:** This only removes the OpenClaw software. It does not undo changes OpenClaw may have already made (e.g. files it edited, emails it sent, or other actions it took).

---

## What is DeClawed?

DeClawed is a small script that **uninstalls OpenClaw** and removes what it installed: the background service, config files, data in `~/.openclaw`, shell hooks, and leftover processes. It works on **macOS, Linux, and Windows**. It does **not** revert changes OpenClaw has already made to your files or accounts (e.g. edits, sent messages, or other actions)—it only removes the software itself.

If you tried OpenClaw and decided it's not for you—or you just want it off your machine—this is the way.

---

## How to use it

You have two options. Pick one.

### Option 1: Ask your AI to do it (when OpenClaw or Cursor still works)

Paste this into your AI chat and send:

```text
Read ~/.cursor/skills/de-claw/SKILL.md and fully uninstall OpenClaw from this machine with a dry-run preview first, then delete everything you safely can.
```

The agent will show you what would be removed, ask if you want a backup of `~/.openclaw`, and then run the uninstall after you confirm.

---

### Option 2: Run one command in the terminal (no AI needed)

Copy **one** line below, paste into your terminal, press Enter. Nothing else to install or clone.

#### macOS / Linux / WSL2

**Uninstall now:**

```bash
curl -fsSL https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.sh | bash -s -- --yes --no-backup
```

**Preview only (see what would be removed, no changes made):**

```bash
curl -fsSL https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.sh | bash -s -- --dry-run
```

To backup your data first, use `--backup ~/Desktop` instead of `--yes --no-backup`.

#### Windows (PowerShell)

**Uninstall now:**

```powershell
irm https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.ps1 -OutFile $env:TEMP\declawed.ps1; & $env:TEMP\declawed.ps1 -Yes -NoBackup
```

**Preview only:**

```powershell
irm https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.ps1 -OutFile $env:TEMP\declawed.ps1; & $env:TEMP\declawed.ps1 -DryRun
```

If PowerShell blocks the script, run once: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

---

## What gets removed?

| Platform | Removed |
|----------|---------|
| **macOS** | LaunchAgent, OpenClaw.app, Application Support folders, Preferences, Keychain entries |
| **Linux** | systemd services, npm package, config under `~/.config` and `~/.local/share` |
| **Windows** | Scheduled tasks, AppData folders, registry keys, PATH entries |
| **All** | `~/.openclaw/` (your data—optional backup first), shell config hooks, Cursor caches, temp files, running OpenClaw processes |
| **Optional** | `~/.cursor/skills/` (you're asked, or use `--keep-skills` to keep it) |

---

## Script options

| Flag | Meaning |
|------|---------|
| `--dry-run` / `-DryRun` | Show what would be removed, don't delete anything |
| `--yes` / `-Yes` | Skip confirmation prompts |
| `--backup [dir]` / `-Backup` | Save `~/.openclaw` to a folder before deleting (e.g. Desktop) |
| `--no-backup` / `-NoBackup` | Don't backup, delete data directly |
| `--keep-skills` / `-KeepSkills` | Leave `~/.cursor/skills` and `~/.agents/skills` alone |

---

## FAQ

**Will this break my system?**  
It only removes OpenClaw-related files and services. The rest of your system is untouched. Restart your terminal after running so PATH updates.

**I want to keep my OpenClaw data (workspaces, history).**  
Use `--backup ~/Desktop` (or any folder). The script will create a timestamped archive before deleting.

**Does DeClawed send any data online?**  
No. No telemetry, no network calls. It's a local script that runs and exits.

**OpenClaw is stuck or won't start. Can I still uninstall?**  
Yes. Use Option 2 (the one-line terminal command). It doesn't need OpenClaw to be running.

---

## Contributing

PRs welcome—especially for other Linux distros, Windows paths we might have missed, or newer OpenClaw versions that change where things are installed. Please run the script (at least with `--dry-run`) before submitting.

---

## License

MIT. Use and modify as you like. Keep it simple—no kernel-level tricks.

---

<div align="center">

DeClawed — one command to uninstall OpenClaw. 🦞 ✂️

</div>
