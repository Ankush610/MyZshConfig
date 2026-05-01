#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  uninstall-zsh-setup.sh — Remove Zsh Environment Setup
#  Reverts shell to bash, removes all installed components
#
#  Flags:
#    --full-clean    also removes ~/.zsh_history and all .zshrc backups
# ════════════════════════════════════════════════════════════════

set -e

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $1"; }
ok()   { echo -e "${GREEN}${BOLD}[ OK ]${RESET}  $1"; }
warn() { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $1"; }
err()  { echo -e "${RED}${BOLD}[ERR ]${RESET}  $1"; exit 1; }

FULL_CLEAN=false
for arg in "$@"; do
  [[ "$arg" == "--full-clean" ]] && FULL_CLEAN=true
done

if [[ $EUID -eq 0 ]]; then
  err "Don't run as root."
fi

echo -e "\n${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Zsh Environment Uninstall — Fedora 44${RESET}"
echo -e "${BOLD}════════════════════════════════════════════════${RESET}\n"

warn "This will remove: zsh plugins, fzf-tab, .zshrc"
warn "DNF packages (zsh, fzf, lsd, bat, neovim) will NOT be removed"
if $FULL_CLEAN; then
  warn "--full-clean: will also remove ~/.zsh_history and all .zshrc backups"
fi
echo -ne "\n${BOLD}Continue? [y/N]:${RESET} "
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Sudo upfront ─────────────────────────────────────────────────
log "Requesting sudo access..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ── Revert shell to bash ─────────────────────────────────────────
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
BASH_PATH=$(which bash)
if [[ "$CURRENT_SHELL" != "$BASH_PATH" ]]; then
  log "Reverting default shell to bash..."
  sudo chsh -s "$BASH_PATH" "$USER"
  ok "Default shell reverted to bash."
else
  ok "Shell is already bash."
fi

# ── Remove Zsh plugins ───────────────────────────────────────────
log "Removing zsh-syntax-highlighting..."
rm -rf ~/.zsh/zsh-syntax-highlighting
ok "zsh-syntax-highlighting removed."

log "Removing zsh-autosuggestions..."
rm -rf ~/.zsh/zsh-autosuggestions
ok "zsh-autosuggestions removed."

log "Removing fzf-tab..."
rm -rf ~/.oh-my-zsh/custom/plugins/fzf-tab
ok "fzf-tab removed."

# cleanup empty dirs
rmdir ~/.zsh 2>/dev/null                        && ok "~/.zsh dir removed."           || true
rmdir ~/.oh-my-zsh/custom/plugins 2>/dev/null   || true
rmdir ~/.oh-my-zsh/custom 2>/dev/null           || true
rmdir ~/.oh-my-zsh 2>/dev/null                  || true

# ── Backup and remove .zshrc ─────────────────────────────────────
if [[ -f ~/.zshrc ]]; then
  BACKUP=~/.zshrc.uninstall.$(date +%Y%m%d_%H%M%S)
  cp ~/.zshrc "$BACKUP"
  rm -f ~/.zshrc
  ok ".zshrc removed (backup saved at $BACKUP)"
else
  warn "No .zshrc found."
fi

# ── Restore previous .zshrc if exists ────────────────────────────
LATEST_BACKUP=$(ls -t ~/.zshrc.backup.* 2>/dev/null | head -1)
if [[ -n "$LATEST_BACKUP" ]]; then
  log "Restoring previous .zshrc from $LATEST_BACKUP..."
  cp "$LATEST_BACKUP" ~/.zshrc
  ok "Previous .zshrc restored."
else
  warn "No previous .zshrc backup found — starting fresh."
fi

# ── Full clean (optional) ────────────────────────────────────────
if $FULL_CLEAN; then
  log "Full clean: removing ~/.zsh_history..."
  rm -f ~/.zsh_history
  ok "~/.zsh_history removed."

  log "Full clean: removing all .zshrc backups..."
  rm -f ~/.zshrc.backup.* ~/.zshrc.uninstall.*
  ok "All .zshrc backups removed."
fi

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}   Uninstall complete!${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "\n  Log out and back in to switch back to bash."
if ! $FULL_CLEAN; then
  echo -e "  Run with ${CYAN}--full-clean${RESET} to also wipe history and backups."
fi
echo ""
