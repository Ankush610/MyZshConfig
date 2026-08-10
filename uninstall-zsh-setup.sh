#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  uninstall-zsh-setup.sh — Remove Zsh Environment Setup
#  Reverts shell to bash, removes installed components.
#
#  Usage: bash uninstall-zsh-setup.sh [--config-only|--full] [--yes]
#    --config-only  remove configs/plugins, keep DNF packages
#    --full         also remove DNF packages, history, backups
#    --yes          skip confirmation prompts (git is kept in this mode)
# ════════════════════════════════════════════════════════════════

set -e

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

LOG=/tmp/zsh-setup-uninstall.log
: > "$LOG"

TOTAL=4
STEP=0

step() { STEP=$((STEP + 1)); echo -e "\n${CYAN}${BOLD}[$STEP/$TOTAL]${RESET} ${BOLD}$1${RESET}"; }
ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
err()  { echo -e "  ${RED}✘${RESET}  $1"; exit 1; }

# run <description> <command...> — quiet, spinner, log tail on failure
run() {
  local msg=$1 rc=0
  shift
  if [[ -t 1 ]]; then
    "$@" >>"$LOG" 2>&1 &
    local pid=$! frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s  %s' "${frames:$((i % 10)):1}" "$msg"
      i=$((i + 1))
      sleep 0.1
    done
    wait "$pid" || rc=$?
    printf '\r\033[K'
  else
    "$@" >>"$LOG" 2>&1 || rc=$?
  fi
  if (( rc != 0 )); then
    echo -e "  ${RED}✘${RESET}  $msg failed (exit $rc) — last lines of log:"
    tail -n 20 "$LOG" | sed 's/^/     /'
    err "Full log: $LOG"
  fi
}

if [[ $EUID -eq 0 ]]; then
  err "Don't run as root."
fi

# ── Args ─────────────────────────────────────────────────────────
MODE=""
YES=""
for arg in "$@"; do
  case "$arg" in
    --config-only) MODE=1 ;;
    --full)        MODE=2 ;;
    --yes)         YES=1 ;;
    *) err "Unknown option: $arg (use --config-only, --full, --yes)" ;;
  esac
done

echo -e "\n${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Zsh Environment Uninstall — Fedora 44${RESET}"
echo -e "${BOLD}════════════════════════════════════════════════${RESET}\n"

# ── Mode selection ───────────────────────────────────────────────
if [[ -z "$MODE" ]]; then
  echo -e "  ${BOLD}Choose uninstall mode:${RESET}\n"
  echo -e "  ${CYAN}1)${RESET} ${BOLD}Config only${RESET}"
  echo -e "     Remove dankshell config and zsh plugins."
  echo -e "     Reverts shell to bash. Keeps all DNF packages installed.\n"
  echo -e "  ${CYAN}2)${RESET} ${BOLD}Full clean${RESET}"
  echo -e "     Everything in option 1, plus removes DNF packages"
  echo -e "     (zsh, fzf, eza, neovim, zoxide, bat, glow) and wipes history/backups.\n"
  echo -e "  ${CYAN}3)${RESET} ${BOLD}Abort${RESET}\n"

  echo -ne "  ${BOLD}Enter choice [1/2/3]:${RESET} "
  read -r MODE
fi

case "$MODE" in
  1) echo -e "\n  → Config-only uninstall selected." ;;
  2) echo -e "\n  → Full clean uninstall selected."; TOTAL=6 ;;
  3) echo "  Aborted."; exit 0 ;;
  *) err "Invalid choice. Run the script again and enter 1, 2, or 3." ;;
esac

if [[ -z "$YES" ]]; then
  echo ""
  echo -ne "${BOLD}Are you sure? This cannot be undone. [y/N]:${RESET} "
  read -r CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi
echo ""

# ── Sudo upfront ─────────────────────────────────────────────────
ok "Requesting sudo access..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ════════════════════════════════════════════════════════════════
#  SHARED STEPS (both modes)
# ════════════════════════════════════════════════════════════════

# ── 1. Revert shell to bash ──────────────────────────────────────
step "Default shell"
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
BASH_PATH=$(command -v bash)
if [[ "$CURRENT_SHELL" != "$BASH_PATH" ]]; then
  sudo chsh -s "$BASH_PATH" "$USER"
  ok "Default shell reverted to bash."
else
  ok "Shell is already bash."
fi

# ── 2. Remove Zsh plugins ────────────────────────────────────────
step "Zsh plugins"
rm -rf ~/.zsh/zsh-syntax-highlighting
ok "zsh-syntax-highlighting removed."
rm -rf ~/.zsh/zsh-autosuggestions
ok "zsh-autosuggestions removed."
rm -rf ~/.oh-my-zsh/custom/plugins/fzf-tab
ok "fzf-tab removed."

# ── 3. Remove dankshell config from .zshrc ───────────────────────
step "Dankshell config"
if [[ -f ~/.zshrc ]]; then
  BACKUP=~/.zshrc.uninstall.$(date +%Y%m%d_%H%M%S)
  cp ~/.zshrc "$BACKUP"
  # Strip only the lines the installer added — keep the user's own config
  sed -i -e '/Dankshell config (added by install-zsh-setup.sh)/d' \
         -e '\|source ~/.zsh/dankshell.zsh|d' ~/.zshrc
  if [[ -z "$(tr -d '[:space:]' < ~/.zshrc)" ]]; then
    # Nothing left — it was the minimal file the installer created
    rm -f ~/.zshrc
    ok ".zshrc removed (backup saved at $BACKUP)"
  else
    ok "Dankshell lines removed — your own .zshrc kept (backup at $BACKUP)"
  fi
else
  warn "No .zshrc found."
fi

rm -f ~/.zsh/dankshell.zsh ~/.zsh/cheatsheet.txt
ok "~/.zsh/dankshell.zsh and cheatsheet removed."

# cleanup empty dirs
rmdir ~/.zsh 2>/dev/null                        && ok "~/.zsh dir removed."  || true
rmdir ~/.oh-my-zsh/custom/plugins 2>/dev/null   || true
rmdir ~/.oh-my-zsh/custom 2>/dev/null           || true
rmdir ~/.oh-my-zsh 2>/dev/null                  || true

# ════════════════════════════════════════════════════════════════
#  FULL CLEAN ONLY (mode 2)
# ════════════════════════════════════════════════════════════════

if [[ "$MODE" == "2" ]]; then

  # ── 5. Remove DNF packages ─────────────────────────────────────
  step "DNF packages"
  PKGS=(zsh fzf eza neovim zoxide bat glow)
  warn "curl will NOT be removed as it is commonly used by other tools."
  if [[ -z "$YES" ]]; then
    echo -ne "  ${BOLD}Also remove git? Other projects on this machine may need it. [y/N]:${RESET} "
    read -r REMOVE_GIT
    [[ "$REMOVE_GIT" =~ ^[Yy]$ ]] && PKGS+=(git)
  fi
  [[ " ${PKGS[*]} " == *" git "* ]] || warn "git will be kept."
  run "Removing ${PKGS[*]}" sudo dnf remove -y "${PKGS[@]}"
  ok "DNF packages removed."

  # ── 6. Remove history and backups ──────────────────────────────
  step "History and backups"
  rm -f ~/.zsh_history
  ok "~/.zsh_history removed."
  rm -rf ~/.local/share/zoxide
  ok "zoxide database removed."
  rm -f ~/.zshrc.uninstall.*
  ok "All .zshrc backups removed."

fi

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}   Uninstall complete!${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "\n  Log out and back in to switch back to bash.\n"
