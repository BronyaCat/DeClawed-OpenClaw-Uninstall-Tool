<div align="center">

### 🌐 语言

[English](README.md) · **简体中文**

---

## ✂️ DeClawed

**OpenClaw 卸载工具**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool)

</div>

---

> **OpenClaw 说：** 真正会干事的 AI。  
> **DeClawed 说：** 真正会回锅的 AI。

当你用够了、想彻底卸掉的时候，DeClawed **从电脑上卸载 OpenClaw**（程序、服务、配置和数据）。一条命令就行，不用 clone，不用一步步手动删。  
**说明：** 本脚本只移除 OpenClaw 软件本身，**不会**还原 OpenClaw 已经做过的改动（例如它改过的文件、发过的邮件或执行过的其他操作）。

---

## DeClawed 是啥？

DeClawed 是一个**卸载 OpenClaw** 的小脚本。它会删掉 OpenClaw 装上的后台服务、配置文件、`~/.openclaw` 里的数据、塞进 Shell 里的钩子，以及还在跑的进程。支持 **macOS、Linux、Windows**。**不会**还原 OpenClaw 已经对电脑做过的事（例如改过的文件、发出去的消息等），只移除软件本身。

如果你试过 OpenClaw 觉得不适合，或者想直接从电脑上卸掉，用这个就行。

---

## 怎么用？

两种方式，任选一种。

### 方式一：让 AI 帮你卸（OpenClaw 或 Cursor 还能用的时候）

把下面这句复制到你的 AI 聊天里发出去：

```text
Read ~/.cursor/skills/de-claw/SKILL.md and fully uninstall OpenClaw from this machine with a dry-run preview first, then delete everything you safely can.
```

AI 会先给你看会删哪些东西、问你要不要备份 `~/.openclaw`，你确认后再执行卸载。

---

### 方式二：终端里一条命令（不依赖 AI）

下面**任选一行**，复制到终端粘贴回车即可。不用先 clone、不用装别的。

#### macOS / Linux / WSL2

**直接卸载：**

```bash
curl -fsSL https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.sh | bash -s -- --yes --no-backup
```

**只预览（只看会删啥，不真删）：**

```bash
curl -fsSL https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.sh | bash -s -- --dry-run
```

想先备份再删？把参数换成 `--backup ~/Desktop` 即可（不用 `--yes --no-backup`）。

#### Windows（PowerShell）

**直接卸载：**

```powershell
irm https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.ps1 -OutFile $env:TEMP\declawed.ps1; & $env:TEMP\declawed.ps1 -Yes -NoBackup
```

**只预览：**

```powershell
irm https://raw.githubusercontent.com/BronyaCat/DeClawed-OpenClaw-Uninstall-Tool/main/scripts/purge.ps1 -OutFile $env:TEMP\declawed.ps1; & $env:TEMP\declawed.ps1 -DryRun
```

如果 PowerShell 报错不让执行，先运行一次：`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

---

## 会删掉哪些东西？

| 平台 | 会清理的内容 |
|------|----------------|
| **macOS** | LaunchAgent、OpenClaw.app、Application Support 相关目录、Preferences、Keychain 里的相关项 |
| **Linux** | systemd 服务、npm 全局包、`~/.config` 和 `~/.local/share` 下的相关配置 |
| **Windows** | 计划任务、AppData 目录、注册表、PATH 里的相关路径 |
| **通用** | `~/.openclaw/`（你的数据，可选先备份）、Shell 配置里的钩子、Cursor 缓存、临时文件、还在运行的 OpenClaw 进程 |
| **可选** | `~/.cursor/skills/`（会询问你是否删除，或加 `--keep-skills` 保留） |

---

## 参数说明

| 参数 | 作用 |
|------|------|
| `--dry-run` / `-DryRun` | 只显示会删什么，不实际删除 |
| `--yes` / `-Yes` | 跳过确认，直接执行 |
| `--backup [目录]` / `-Backup` | 删除前把 `~/.openclaw` 打包到指定目录（如桌面） |
| `--no-backup` / `-NoBackup` | 不备份，直接删数据 |
| `--keep-skills` / `-KeepSkills` | 保留 `~/.cursor/skills` 和 `~/.agents/skills` |

---

## 常见问题

**会把我系统搞坏吗？**  
不会。只动和 OpenClaw 相关的东西，其它不动。跑完后建议重启一下终端，让 PATH 生效。

**我想保留 OpenClaw 里的工作区、对话记录。**  
用 `--backup ~/Desktop`（或任意目录）。脚本会先打一个带时间的压缩包，再删。

**DeClawed 会联网、上传数据吗？**  
不会。无埋点、无上报，就是本地跑完就退出。

**OpenClaw 已经卡死或打不开了，还能卸吗？**  
可以。用方式二那条终端命令，不依赖 OpenClaw 是否在运行。

---

## 参与贡献

欢迎 PR：比如支持更多 Linux 发行版、补全 Windows 上的路径、或适配新版 OpenClaw 的安装位置。提 PR 前请至少用 `--dry-run` 跑一遍确认。

---

## 协议

MIT。可随意使用和修改。保持简单，不碰系统底层。

---

<div align="center">

DeClawed — 一条命令，卸掉 OpenClaw。🦞 ✂️

</div>
