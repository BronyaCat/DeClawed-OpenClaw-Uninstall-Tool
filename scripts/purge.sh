#!/usr/bin/env bash
# de-claw — OpenClaw full uninstall script (macOS + Linux)
# Supports: macOS 12+, Ubuntu/Debian/RHEL Linux, WSL2
#
# Usage:
#   bash purge.sh [options]
#
# Options:
#   --dry-run           Preview only, do not delete anything
#   --yes / -y          Skip all interactive confirmations
#   --backup [dir]      Backup workspace data to directory (default ~/Desktop or ~)
#   --no-backup         Skip backup prompts and delete directly
#   --keep-skills       Keep ~/.cursor/skills and ~/.agents/skills
#   --help / -h         Show help

set -euo pipefail

# ─── 颜色 & 样式 ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
  BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; DIM=''; NC=''; BLUE=''; MAGENTA=''
fi

# ─── 参数解析 ─────────────────────────────────────────────────────────────────
DRY_RUN=false
AUTO_YES=false
BACKUP_DIR=""
NO_BACKUP=false
KEEP_SKILLS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=true ;;
    --yes|-y)       AUTO_YES=true ;;
    --backup)       BACKUP_DIR="${2:-}"; [[ -n "$BACKUP_DIR" ]] && shift ;;
    --no-backup)    NO_BACKUP=true ;;
    --keep-skills)  KEEP_SKILLS=true ;;
    --help|-h)
      grep '^#' "$0" | head -15 | sed 's/^# \?//'
      exit 0 ;;
    *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
  esac
  shift
done

# ─── 平台检测 ─────────────────────────────────────────────────────────────────
OS="unknown"
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    OS="linux"
    if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
      OS="wsl"
    fi
    ;;
  *) echo -e "${RED}Unsupported operating system: $(uname -s)${NC}" >&2; exit 1 ;;
esac

# ─── Helper functions ─────────────────────────────────────────────────────────
log_section() { echo -e "\n${BOLD}${CYAN}▶ $1${NC}"; }
log_item()    { echo -e "  ${DIM}→${NC} $1"; }
log_ok()      { echo -e "  ${GREEN}✓${NC} $1"; }
log_skip()    { echo -e "  ${DIM}✗ Skipped: $1${NC}"; }
log_warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
log_info()    { echo -e "  ${BLUE}ℹ${NC} $1"; }

generate_claw_phrase() {
  # A tiny bit of claw‑themed internet meme energy (keep the fun)
  local phrases=(
    "no claw, no law, just rm -rf"
    "one does not simply de-claw prod"
    "let the claws go silent"
    "this is how the claw ends"
    "bye bye claw, hello clean slate"
  )
  local idx=$((RANDOM % ${#phrases[@]}))
  echo "${phrases[$idx]}"
}

removed_count=0
skipped_count=0

remove_path() {
  local path="$1"
  local label="${2:-$path}"
  if [[ -e "$path" || -L "$path" ]]; then
    if $DRY_RUN; then
      log_item "[DRY-RUN] would remove: $path"
    else
      rm -rf "$path"
      log_ok "Removed: $label"
    fi
    removed_count=$((removed_count + 1))
  else
    log_skip "$label"
    skipped_count=$((skipped_count + 1))
  fi
}

run_cmd() {
  local desc="$1"; shift
  if $DRY_RUN; then
    log_item "[DRY-RUN] would run: $*"
  else
    if "$@" 2>/dev/null; then
      log_ok "$desc"
    else
      log_warn "$desc (ignored error)"
    fi
  fi
}

confirm() {
  $AUTO_YES && return 0
  local prompt="$1"
  local default="${2:-n}"
  if [[ "$default" == "y" ]]; then
    echo -en "\n${YELLOW}$prompt [Y/n] ${NC}"
  else
    echo -en "\n${YELLOW}$prompt [y/N] ${NC}"
  fi
  read -r answer
  if [[ "$default" == "y" ]]; then
    [[ ! "$answer" =~ ^[Nn]$ ]]
  else
    [[ "$answer" =~ ^[Yy]$ ]]
  fi
}

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e "${BOLD}${RED}"
cat << 'BANNER'
   ██████╗ ███████╗      ██████╗██╗      █████╗ ██╗    ██╗
   ██╔══██╗██╔════╝     ██╔════╝██║     ██╔══██╗██║    ██║
   ██║  ██║█████╗  ─── ██║     ██║     ███████║██║ █╗ ██║
   ██║  ██║██╔══╝      ██║     ██║     ██╔══██║██║███╗██║
   ██████╔╝███████╗    ╚██████╗███████╗██║  ██║╚███╔███╔╝
   ╚═════╝ ╚══════╝     ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝
BANNER
echo -e "${NC}"
echo -e "${BOLD}  de-claw — OpenClaw full uninstall tool v1.1${NC}"
echo -e "${DIM}  macOS · Linux · WSL2 | supports OpenClaw 2026.x${NC}"
echo ""
echo -e "  Platform: ${CYAN}${BOLD}$OS${NC}  |  User: ${CYAN}${BOLD}$(whoami)${NC}  |  Home: ${CYAN}${BOLD}$HOME${NC}"
echo ""

if $DRY_RUN; then
  echo -e "  ${YELLOW}${BOLD}⚡ DRY-RUN mode: preview only, no changes will be made${NC}"
  echo ""
fi

# ─── 扫描安装足迹 ─────────────────────────────────────────────────────────────
echo -e "${BOLD}  Scanning for OpenClaw footprints...${NC}"
echo ""

FOUND_COUNT=0
found_items=()

check_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    echo -e "  ${GREEN}●${NC} $label"
    FOUND_COUNT=$((FOUND_COUNT + 1))
    found_items+=("$path")
  else
    echo -e "  ${DIM}○ (not found) $label${NC}"
  fi
}

# 服务
if [[ "$OS" == "macos" ]]; then
  check_exists ~/Library/LaunchAgents/ai.openclaw.gateway.plist "LaunchAgent: ai.openclaw.gateway"
elif [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
  check_exists ~/.config/systemd/user/openclaw-gateway.service  "systemd user service: openclaw-gateway"
  check_exists /etc/systemd/system/openclaw-gateway.service     "systemd system service (root): openclaw-gateway"
fi

# npm 全局包
NPM_ROOT=$(npm root -g 2>/dev/null || echo "")
if [[ -n "$NPM_ROOT" && -d "$NPM_ROOT/openclaw" ]]; then
  check_exists "$NPM_ROOT/openclaw" "npm 全局包: openclaw"
fi
NPM_BIN=$(npm bin -g 2>/dev/null || dirname "$NPM_ROOT")/bin
check_exists "$NPM_BIN/openclaw" "npm 全局二进制: openclaw"
check_exists "$HOME/.local/bin/openclaw" "~/.local/bin/openclaw"

# macOS 特有
if [[ "$OS" == "macos" ]]; then
  check_exists /Applications/OpenClaw.app                          "App: /Applications/OpenClaw.app"
  check_exists ~/Applications/OpenClaw.app                         "App: ~/Applications/OpenClaw.app"
  check_exists ~/Library/Application\ Support/OpenClaw             "Application Support/OpenClaw"
  check_exists ~/Library/Application\ Support/clawdbot             "Application Support/clawdbot"
  check_exists ~/Library/Application\ Support/clawdis              "Application Support/clawdis"
  check_exists ~/Library/Application\ Support/clawhub              "Application Support/clawhub"
  check_exists ~/Library/Preferences/ai.openclaw.mac.plist         "Preferences/ai.openclaw.mac.plist"
  check_exists ~/Library/Preferences/ai.openclaw.shared.plist      "Preferences/ai.openclaw.shared.plist"
fi

# Linux 特有
if [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
  check_exists ~/.config/OpenClaw   "~/.config/OpenClaw"
  check_exists ~/.config/clawdbot   "~/.config/clawdbot"
  check_exists ~/.config/clawdis    "~/.config/clawdis"
  check_exists ~/.config/clawhub    "~/.config/clawhub"
  check_exists ~/.local/share/OpenClaw  "~/.local/share/OpenClaw"
fi

# 数据目录
check_exists ~/.openclaw "~/.openclaw （工作区/凭证/日志）"

# Cursor MCP 缓存（通配符匹配）
for d in ~/.cursor/projects/*openclaw* ~/.cursor/projects/*-openclaw; do
  [[ -e "$d" ]] && check_exists "$d" "Cursor MCP 缓存: $(basename "$d")"
done

# 临时文件
check_exists /tmp/openclaw "/tmp/openclaw 临时文件"

# Shell RC 条目
for rc in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.profile ~/.config/fish/config.fish; do
  if [[ -f "$rc" ]] && grep -qi "openclaw" "$rc" 2>/dev/null; then
    echo -e "  ${YELLOW}●${NC} Shell RC 条目: $rc"
    FOUND_COUNT=$((FOUND_COUNT + 1))
  fi
done

# 进程
OPENCLAW_PIDS=$(pgrep -f "openclaw\|OpenClaw\.app\|OpenClaw\.app" 2>/dev/null || echo "")
if [[ -n "$OPENCLAW_PIDS" ]]; then
  echo -e "  ${YELLOW}●${NC} 运行中的 OpenClaw 进程: $(echo $OPENCLAW_PIDS | tr '\n' ' ')"
  FOUND_COUNT=$((FOUND_COUNT + 1))
fi

echo ""
echo -e "  ${BOLD}Found ${FOUND_COUNT} installation footprints${NC}"

if [[ $FOUND_COUNT -eq 0 ]]; then
  echo -e "${GREEN}\n  OpenClaw does not appear to be installed (or is already fully removed).${NC}"
  exit 0
fi

# ─── 备份选项 ─────────────────────────────────────────────────────────────────
if [[ -d ~/.openclaw ]] && ! $NO_BACKUP; then
  echo ""
  DATA_SIZE=$(du -sh ~/.openclaw 2>/dev/null | cut -f1 || echo "unknown")
  echo -e "  ${BOLD}Workspace data directory:${NC} ~/.openclaw (${CYAN}${DATA_SIZE}${NC})"
  echo -e "  ${DIM}Contains: workspaces, API keys, conversation history, custom config${NC}"

  if [[ -z "$BACKUP_DIR" ]]; then
    if confirm "  Backup workspace data before deleting? (strongly recommended)" "y"; then
      # Decide default backup path
      if [[ "$OS" == "macos" ]] && [[ -d ~/Desktop ]]; then
        DEFAULT_BACKUP=~/Desktop
      else
        DEFAULT_BACKUP=~
      fi
      if ! $AUTO_YES; then
        echo -en "  ${YELLOW}Save backup to [${DEFAULT_BACKUP}]: ${NC}"
        read -r user_backup_dir
        BACKUP_DIR="${user_backup_dir:-$DEFAULT_BACKUP}"
      else
        BACKUP_DIR="$DEFAULT_BACKUP"
      fi
    fi
  fi

  if [[ -n "$BACKUP_DIR" ]]; then
    BACKUP_DIR="${BACKUP_DIR/#\~/$HOME}"  # 展开 ~
    if [[ ! -d "$BACKUP_DIR" ]]; then
      echo -e "  ${YELLOW}Directory does not exist, creating: $BACKUP_DIR${NC}"
      mkdir -p "$BACKUP_DIR" 2>/dev/null || { echo -e "  ${RED}无法创建目录，跳过备份${NC}"; BACKUP_DIR=""; }
    fi

    if [[ -n "$BACKUP_DIR" ]]; then
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)
      BACKUP_FILE="$BACKUP_DIR/openclaw-backup-$TIMESTAMP.tar.gz"

      if $DRY_RUN; then
        log_item "[DRY-RUN] would backup ~/.openclaw to: $BACKUP_FILE"
      else
        echo -en "  Creating backup..."
        if tar -czf "$BACKUP_FILE" -C "$HOME" .openclaw 2>/dev/null; then
          BACKUP_SIZE=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1 || echo "?")
          echo -e "\r  ${GREEN}✓ Backup created:${NC} ${BOLD}$BACKUP_FILE${NC} (${BACKUP_SIZE})"
        else
          echo -e "\r  ${RED}✗ Backup failed. Continue anyway?${NC}"
          confirm "  Continue uninstall without backup?" || { echo "Cancelled."; exit 0; }
        fi
      fi
    fi
  fi
fi

# ─── Final confirmation ───────────────────────────────────────────────────────
if ! confirm "Proceed with uninstalling OpenClaw? This action is IRREVERSIBLE." "n"; then
  echo -e "${YELLOW}\n  Uninstall cancelled.${NC}"
  exit 0
fi

if ! $DRY_RUN; then
  # Extra safety: random phrase confirmation to avoid accidental destructive runs
  CLAW_PHRASE="$(generate_claw_phrase)"
  echo ""
  echo -e "  ${YELLOW}Type the following phrase exactly to confirm irreversible uninstall:${NC}"
  echo -e "    ${BOLD}${CLAW_PHRASE}${NC}"
  echo ""
  echo -en "  Confirm phrase: "
  read -r typed_phrase
  if [[ "$typed_phrase" != "$CLAW_PHRASE" ]]; then
    echo -e "${YELLOW}\n  Phrase mismatch, uninstall aborted.${NC}"
    exit 0
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 1: stop running OpenClaw processes
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Stopping OpenClaw processes"

if [[ -n "$OPENCLAW_PIDS" ]]; then
  for pid in $OPENCLAW_PIDS; do
    PROC_NAME=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
    if $DRY_RUN; then
      log_item "[DRY-RUN] would kill PID $pid ($PROC_NAME)"
    else
      kill -TERM "$pid" 2>/dev/null && log_ok "Killed PID $pid ($PROC_NAME)" || log_warn "Could not kill PID $pid (may require sudo)"
    fi
  done
  sleep 1
  # 强制清除残余
  REMAINING=$(pgrep -f "openclaw\|OpenClaw\.app" 2>/dev/null || echo "")
  if [[ -n "$REMAINING" ]]; then
    for pid in $REMAINING; do
      $DRY_RUN || kill -KILL "$pid" 2>/dev/null || true
    done
  fi
else
  log_skip "No running OpenClaw processes"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 2: stop and remove system services
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Stopping and removing system services"

if [[ "$OS" == "macos" ]]; then
  PLIST=~/Library/LaunchAgents/ai.openclaw.gateway.plist
  if launchctl list 2>/dev/null | grep -q "ai.openclaw.gateway"; then
    run_cmd "Stop LaunchAgent" launchctl bootout "gui/$(id -u)" "$PLIST"
  else
    log_skip "LaunchAgent is not running"
  fi
  remove_path "$PLIST" "LaunchAgent plist: ai.openclaw.gateway"

elif [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
  # User-level systemd service
  if systemctl --user is-active openclaw-gateway.service &>/dev/null; then
    run_cmd "Stop user systemd service" systemctl --user stop openclaw-gateway.service
    run_cmd "Disable user systemd service" systemctl --user disable openclaw-gateway.service
  else
    log_skip "User systemd service is not running"
  fi
  SVCFILE_USER=~/.config/systemd/user/openclaw-gateway.service
  if remove_path "$SVCFILE_USER" "systemd user service file"; then
    run_cmd "Reload systemd user daemon" systemctl --user daemon-reload
  fi

  # System-level systemd service (requires sudo)
  if [[ -f /etc/systemd/system/openclaw-gateway.service ]]; then
    log_warn "Found system-level systemd service, sudo will be required"
    if $DRY_RUN; then
      log_item "[DRY-RUN] would run: sudo systemctl stop/disable openclaw-gateway.service"
    else
      sudo systemctl stop openclaw-gateway.service 2>/dev/null || true
      sudo systemctl disable openclaw-gateway.service 2>/dev/null || true
      sudo rm -f /etc/systemd/system/openclaw-gateway.service
      sudo systemctl daemon-reload 2>/dev/null || true
      log_ok "Removed system-level systemd service"
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 3: uninstall global npm package
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Uninstalling global npm package"

NPM_UNINSTALLED=false

# 方式 A：npm uninstall（标准路径）
if command -v npm &>/dev/null; then
  if npm list -g --depth=0 2>/dev/null | grep -q "openclaw"; then
    run_cmd "npm uninstall -g openclaw" npm uninstall -g openclaw
    NPM_UNINSTALLED=true
  else
    log_skip "npm global package openclaw is not installed (or npm is broken)"
  fi
else
  log_warn "npm not found, will try deleting files directly"
fi

# Fallback: delete package directory directly when npm is broken
for candidate_root in \
    "$(npm root -g 2>/dev/null || echo '')" \
    "/opt/homebrew/lib/node_modules" \
    "/usr/local/lib/node_modules" \
    "$HOME/.npm-global/lib/node_modules" \
    "$HOME/.local/lib/node_modules" \
    "${NVM_DIR:-}/versions/node/$(node -v 2>/dev/null)/lib/node_modules"; do
  [[ -z "$candidate_root" ]] && continue
  PKG_DIR="$candidate_root/openclaw"
  if [[ -d "$PKG_DIR" ]]; then
    remove_path "$PKG_DIR" "npm 包目录: $PKG_DIR"
    break
  fi
done

# Cleanup binaries
for bin_candidate in \
    "$(npm bin -g 2>/dev/null || echo '')/openclaw" \
    /opt/homebrew/bin/openclaw \
    /usr/local/bin/openclaw \
    ~/.local/bin/openclaw \
    ~/.npm-global/bin/openclaw; do
  [[ -z "$bin_candidate" ]] && continue
  [[ -e "$bin_candidate" ]] && remove_path "$bin_candidate" "openclaw binary: $bin_candidate"
done

# ═══════════════════════════════════════════════════════════════════════════════
# Step 4: delete app bundle (macOS only)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$OS" == "macos" ]]; then
  log_section "Removing OpenClaw application"
  remove_path /Applications/OpenClaw.app   "/Applications/OpenClaw.app"
  remove_path ~/Applications/OpenClaw.app  "~/Applications/OpenClaw.app"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 5: clean Application Support / XDG data directories
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Cleaning application data directories"

if [[ "$OS" == "macos" ]]; then
  for dir in OpenClaw clawdbot clawdis clawhub; do
    remove_path ~/Library/Application\ Support/$dir "Application Support/$dir"
  done
elif [[ "$OS" == "linux" || "$OS" == "wsl" ]]; then
  for dir in OpenClaw clawdbot clawdis clawhub; do
    remove_path ~/.config/$dir          "~/.config/$dir"
    remove_path ~/.local/share/$dir     "~/.local/share/$dir"
  done
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 6: delete Preferences (macOS only)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$OS" == "macos" ]]; then
  log_section "Removing Preferences files"
  remove_path ~/Library/Preferences/ai.openclaw.mac.plist    "Preferences/ai.openclaw.mac.plist"
  remove_path ~/Library/Preferences/ai.openclaw.shared.plist "Preferences/ai.openclaw.shared.plist"
  # ByHost directory may contain UUID‑named cache files
  for f in ~/Library/Preferences/ByHost/ai.openclaw.*.plist; do
    [[ -e "$f" ]] && remove_path "$f" "Preferences/ByHost/$(basename "$f")"
  done
  # Clear NSUserDefaults cache
  $DRY_RUN || defaults delete ai.openclaw.mac 2>/dev/null || true
  $DRY_RUN || defaults delete ai.openclaw.shared 2>/dev/null || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 7: delete ~/.openclaw data directory
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Removing ~/.openclaw data directory"

if [[ -d ~/.openclaw ]]; then
  if [[ -n "$BACKUP_DIR" ]] || $NO_BACKUP; then
    remove_path ~/.openclaw "~/.openclaw (workspaces/credentials/logs)"
  else
    DATA_SIZE=$(du -sh ~/.openclaw 2>/dev/null | cut -f1 || echo "?")
    if confirm "  Final confirmation: permanently delete ~/.openclaw (${DATA_SIZE})?"; then
      remove_path ~/.openclaw "~/.openclaw (workspaces/credentials/logs)"
    else
      log_warn "Skipped ~/.openclaw (user chose to keep it)"
    fi
  fi
else
  log_skip "~/.openclaw does not exist"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 8: clean OpenClaw entries from shell RC files
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Cleaning OpenClaw entries from shell RC files"

clean_shell_rc() {
  local rc_file="$1"
  [[ ! -f "$rc_file" ]] && return

  if ! grep -qi "openclaw" "$rc_file" 2>/dev/null; then
    log_skip "$rc_file (no OpenClaw entries)"
    return
  fi

  # Show affected lines
  local matched_lines
  matched_lines=$(grep -n -i "openclaw" "$rc_file" 2>/dev/null || echo "")

  if $DRY_RUN; then
    log_item "[DRY-RUN] would remove the following lines from $rc_file:"
    echo "$matched_lines" | sed 's/^/         /'
    return
  fi

  # Use Python 3 to safely remove lines that mention OpenClaw (and adjacent comments)
  python3 - "$rc_file" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, 'r') as f:
    lines = f.readlines()

cleaned = []
i = 0
while i < len(lines):
    line = lines[i]
    # 如果当前行包含 openclaw（不区分大小写），跳过
    if re.search(r'openclaw', line, re.IGNORECASE):
        # 如果前一行保留内容是注释形式且已经被加入 cleaned，检查是否是 openclaw 相关注释
        if cleaned and re.match(r'^\s*#.*openclaw', cleaned[-1], re.IGNORECASE):
            cleaned.pop()
        i += 1
        continue
    # 如果当前行是注释且下一行含 openclaw，一起跳过
    if re.match(r'^\s*#', line) and i + 1 < len(lines):
        next_line = lines[i + 1]
        if re.search(r'openclaw', next_line, re.IGNORECASE):
            i += 2
            continue
    cleaned.append(line)
    i += 1

# 删除多余的空行（连续3个以上空行合并为2个）
result = re.sub(r'\n{3,}', '\n\n', ''.join(cleaned))
with open(path, 'w') as f:
    f.write(result)
PYEOF

  log_ok "Cleaned OpenClaw entries from $rc_file"
  removed_count=$((removed_count + 1))
}

clean_shell_rc ~/.bashrc
clean_shell_rc ~/.bash_profile
clean_shell_rc ~/.zshrc
clean_shell_rc ~/.profile
clean_shell_rc ~/.config/fish/config.fish

# ═══════════════════════════════════════════════════════════════════════════════
# Step 9: clean Cursor / IDE integration files
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Cleaning Cursor / IDE integration"

# MCP 项目缓存（通配符匹配）
for d in ~/.cursor/projects/*openclaw* ~/.cursor/projects/*-openclaw; do
  [[ -e "$d" ]] && remove_path "$d" "Cursor MCP cache: $(basename "$d")"
done

# Cursor extensions (if any openclaw-related extensions exist)
for ext in ~/.cursor/extensions/*openclaw* ~/.cursor/extensions/*claw*; do
  [[ -e "$ext" ]] && remove_path "$ext" "Cursor extension: $(basename "$ext")"
done

# ═══════════════════════════════════════════════════════════════════════════════
# Step 10: clean temporary files
# ═══════════════════════════════════════════════════════════════════════════════
log_section "Cleaning temporary files"

for tmp_path in /tmp/openclaw* /tmp/claw* "${TMPDIR:-/tmp}"/openclaw* "${TMPDIR:-/tmp}"/claw*; do
  [[ -e "$tmp_path" ]] && remove_path "$tmp_path" "temporary file: $tmp_path"
done

# macOS: remove any Keychain entries
if [[ "$OS" == "macos" ]]; then
  if security find-generic-password -s "openclaw" &>/dev/null 2>&1; then
    if $DRY_RUN; then
      log_item "[DRY-RUN] would delete openclaw credentials from Keychain"
    else
      security delete-generic-password -s "openclaw" 2>/dev/null && log_ok "Deleted Keychain entry: openclaw" || true
    fi
  else
  log_skip "No openclaw credentials found in Keychain"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Step 11: optional cleanup of Skills directories
# ═══════════════════════════════════════════════════════════════════════════════
if ! $KEEP_SKILLS; then
  log_section "Cleaning Skills directories (optional)"
  echo -e "  ${YELLOW}Note: these directories may contain your own unrelated Skills${NC}"

  if [[ -d ~/.cursor/skills ]]; then
    if confirm "  Delete ~/.cursor/skills (all personal Skills)?" ; then
      remove_path ~/.cursor/skills "~/.cursor/skills"
    else
      log_warn "Skipped ~/.cursor/skills"
    fi
  else
    log_skip "~/.cursor/skills 不存在"
  fi

  if [[ -d ~/.agents/skills ]]; then
    if confirm "  Delete ~/.agents/skills (Agents Skills)?" ; then
      remove_path ~/.agents/skills "~/.agents/skills"
    else
      log_warn "Skipped ~/.agents/skills"
    fi
  else
    log_skip "~/.agents/skills 不存在"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Final summary
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $DRY_RUN; then
  echo -e "${YELLOW}${BOLD}  [DRY-RUN] Preview completed${NC}"
  echo -e "  Would delete ${BOLD}${removed_count}${NC} items, ${BOLD}${skipped_count}${NC} not found/skipped"
  echo -e "${DIM}  Re-run without --dry-run to actually uninstall.${NC}"
else
  echo -e "${GREEN}${BOLD}  ✅ de-claw complete!${NC}"
  echo -e "  Deleted ${BOLD}${removed_count}${NC} items, ${BOLD}${skipped_count}${NC} not found/skipped"
  [[ -n "$BACKUP_DIR" ]] && echo -e "  ${GREEN}Backup saved at:${NC} $BACKUP_FILE"
  echo ""
  echo -e "${DIM}  Recommended next steps:${NC}"
  echo -e "${DIM}  1. Restart your terminal (or exec \$SHELL) to refresh PATH${NC}"
  echo -e "${DIM}  2. If you no longer need this helper, remove it: rm -rf ~/.cursor/skills/de-claw${NC}"
fi
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
