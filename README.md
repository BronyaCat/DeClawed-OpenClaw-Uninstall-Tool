<div align="center">

# ✂️ DeClawed

**OpenClaw Uninstall Tool**

*You gave OpenClaw your kernel. Time to take it back.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

</div>

---

> *OpenClaw said "one click to do everything."*  
> *This script says "one command to undo all of it."*
>
> Because your computer should belong to **you** —  
> not to a WebSocket, a kernel module, or 341 malicious ClawHub skills.

---

## What is this?

**DeClawed** is a clean, no-drama uninstaller for [OpenClaw](https://openclaw.ai).

It removes:

- 🦞 The OpenClaw daemon and all background processes  
- 📦 ClawHub skills (yes, including the sketchy ones)  
- 📝 Injected shell hooks (`~/.bashrc`, `~/.zshrc`, PowerShell profiles)  
- 🗑️ Residual config files, caches, and telemetry endpoints  
- 🔐 That Ring 0 kernel extension you definitely didn't read the fine print about  

When it's done, your machine is yours again.

---

## Why does this exist?

A few months ago, OpenClaw passed Linux in GitHub stars in under 90 days.  
Linux took 14 years to get there.

Everyone was very excited.

Then the CVEs started dropping.

| CVE | Summary | Severity |
|-----|---------|----------|
| CVE-2026-25253 | One malicious link → WebSocket brute-force → all your SSH keys, API tokens, browser history | 🔴 Critical |
| + 340 others | ClawHub marketplace filled with malicious Skills before anyone noticed | 🔴 Critical |

Security researchers described it as:

> *"Like handing a stranger your house key, car key, and bank card at the same time — but the stranger has a GitHub star count."*

DeClawed exists because the official uninstall docs are three pages of YAML and a prayer.

---

## Quickstart

Two ways to use it: **let the Agent do it** (one line in chat), or **run the script yourself** (one command in the terminal).

### 1️⃣ Agent-driven (Cursor / OpenClaw chat)

Copy-paste this into your AI chat and send:

```text
Read ~/.cursor/skills/de-claw/SKILL.md and fully uninstall OpenClaw from this machine with a dry-run preview first, then delete everything you safely can.
```

The Agent will: dry-run preview → ask about backup → perform uninstall after confirmation.

---

### 2️⃣ Direct script (terminal)

Clone the repo (replace with your GitHub username if you forked):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/declawed.git
cd declawed
```

#### macOS / Linux / WSL2

**One-line uninstall** (no backup, non-interactive):

```bash
bash scripts/purge.sh --yes --no-backup
```

If you already have it at `~/.cursor/skills/de-claw` (e.g. as a Cursor Skill):

```bash
bash ~/.cursor/skills/de-claw/scripts/purge.sh --yes --no-backup
```

**Preview first** (safe, deletes nothing):

```bash
bash scripts/purge.sh --dry-run
```

**With backup to Desktop:**

```bash
bash scripts/purge.sh --backup ~/Desktop
```

#### Windows (PowerShell)

**One-line uninstall:**

```powershell
.\scripts\purge.ps1 -Yes -NoBackup
```

If the repo is at `~\.cursor\skills\de-claw`:

```powershell
~\.cursor\skills\de-claw\scripts\purge.ps1 -Yes -NoBackup
```

**Preview first:**

```powershell
.\scripts\purge.ps1 -DryRun
```

> 💡 If PowerShell blocks scripts, run once:  
> `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

---

## What it looks like

```
   ██████╗ ███████╗      ██████╗██╗      █████╗ ██╗    ██╗
   ██╔══██╗██╔════╝     ██╔════╝██║     ██╔══██╗██║    ██║
   ██║  ██║█████╗  ─── ██║     ██║     ███████║██║ █╗ ██║
   ██║  ██║██╔══╝      ██║     ██║     ██╔══██║██║███╗██║
   ██████╔╝███████╗    ╚██████╗███████╗██║  ██║╚███╔███╔╝
   ╚═════╝ ╚══════╝     ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝

  de-claw — OpenClaw full uninstall tool v1.1
  Platform: macos  |  User: you  |  Home: /Users/you

  Scanning for OpenClaw footprints...
  ● LaunchAgent: ai.openclaw.gateway
  ● npm global package: openclaw
  ● ~/.openclaw (workspaces/credentials/logs)

  Found 3 installation footprints
  ...
  ✅ de-claw complete!
  Deleted 12 items, 2 not found/skipped
  ✅ Closed 341 doors you didn't know were open.
```

---

## Script options

| Flag | Description |
|------|-------------|
| `--dry-run` / `-DryRun` | Preview only, no deletions |
| `--yes` / `-Yes` | Skip all confirmations |
| `--backup [dir]` / `-Backup` | Backup `~/.openclaw` before delete (e.g. to Desktop) |
| `--no-backup` / `-NoBackup` | Skip backup and delete directly |
| `--keep-skills` / `-KeepSkills` | Keep `~/.cursor/skills` and `~/.agents/skills` |

---

## What gets cleaned

| Platform | Removed |
|----------|---------|
| **macOS** | LaunchAgent, npm package, `OpenClaw.app`, Application Support, Preferences, Keychain |
| **Linux** | systemd services, npm package, `~/.config` & `~/.local/share` (OpenClaw/clawdbot/clawdis/clawhub) |
| **Windows** | Task Scheduler tasks, npm package, AppData, registry keys, PATH entries |
| **All** | `~/.openclaw/`, shell RC hooks, Cursor MCP caches, temp files, running processes |
| **Optional** | `~/.cursor/skills/`, `~/.agents/skills/` (prompted unless `--keep-skills`) |

---

## FAQ

**Q: Will this break my workflow?**  

A: If your entire workflow depended on an AI agent with Ring 0 kernel access and 341 unvetted third-party plugins, then: yes, briefly. You're welcome.

**Q: I bought a Mac mini specifically for OpenClaw during the shortage. Does that affect anything?**  

A: No. The Mac mini is still a great computer. It just doesn't need a claw. *Run this script before you panic-buy another one.*

**Q: My OpenClaw is doing things I didn't ask it to do.**  

A: That's not a question. Also: run this script immediately.

**Q: What about Moltbook?**  

A: Moltbook had 1.5 million "users," 99% of which were AI-generated accounts talking to each other about how great OpenClaw is. We don't touch Moltbook. Some experiments are better left alone. *This script will not create any fake accounts for you.*

**Q: Does DeClawed phone home?**  

A: No telemetry. No analytics. No WebSocket server listening on port 9999. Just a script that does exactly what it says on the label, then exits.

---

## Philosophy

OpenClaw is an impressive piece of engineering. Genuinely.

The problem isn't ambition — it's the assumption that "helpful" means "having access to everything, always." A surgeon is helpful. A surgeon who also holds your house keys while operating is a different kind of problem.

DeClawed doesn't take a side in the AI debate.  
It just believes your computer should require your permission to do things on your behalf.

---

## Contributing

PRs welcome. Especially for:

- Edge cases on obscure Linux distros  
- Windows paths we missed  
- New OpenClaw versions that move things around (they will)  

Please test before submitting. This script touches system-level files.

---

## License

MIT. Do whatever you want. Just don't give it Ring 0 access.

---

<div align="center">

*In memory of all the Mac minis that sold out in the winter of 2026.*  
*They didn't deserve this.*

🦞 ✂️

</div>
