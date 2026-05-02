#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  uninstall-zsh-setup.sh — Remove Zsh Environment Setup
#  Reverts shell to bash, removes all installed components
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

if [[ $EUID -eq 0 ]]; then
  err "Don't run as root."
fi

echo -e "\n${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Zsh Environment Uninstall — Fedora 44${RESET}"
echo -e "${BOLD}════════════════════════════════════════════════${RESET}\n"

# ── Mode selection ───────────────────────────────────────────────
echo -e "  ${BOLD}Choose uninstall mode:${RESET}\n"
echo -e "  ${CYAN}1)${RESET} ${BOLD}Config only${RESET}"
echo -e "     Remove .zshrc, Ghostty cursor shader, and zsh plugins."
echo -e "     Reverts shell to bash. Keeps all DNF packages installed.\n"
echo -e "  ${CYAN}2)${RESET} ${BOLD}Full clean${RESET}"
echo -e "     Everything in option 1, plus removes DNF packages"
echo -e "     (zsh, fzf, eza, neovim, git) and wipes history/backups.\n"
echo -e "  ${CYAN}3)${RESET} ${BOLD}Abort${RESET}\n"

echo -ne "  ${BOLD}Enter choice [1/2/3]:${RESET} "
read -r MODE

case "$MODE" in
  1) echo -e "\n  → Config-only uninstall selected." ;;
  2) echo -e "\n  → Full clean uninstall selected." ;;
  3) echo "  Aborted."; exit 0 ;;
  *) err "Invalid choice. Run the script again and enter 1, 2, or 3." ;;
esac

echo ""
echo -ne "${BOLD}Are you sure? This cannot be undone. [y/N]:${RESET} "
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
echo ""

# ── Sudo upfront ─────────────────────────────────────────────────
log "Requesting sudo access..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ════════════════════════════════════════════════════════════════
#  SHARED STEPS (both modes)
# ════════════════════════════════════════════════════════════════

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
rmdir ~/.zsh 2>/dev/null                        && ok "~/.zsh dir removed."  || true
rmdir ~/.oh-my-zsh/custom/plugins 2>/dev/null   || true
rmdir ~/.oh-my-zsh/custom 2>/dev/null           || true
rmdir ~/.oh-my-zsh 2>/dev/null                  || true

# ── Remove Ghostty cursor shader ─────────────────────────────────
log "Removing Ghostty cursor shader..."
GHOSTTY_SHADER_DIR=~/.config/ghostty/shaders/ghostty-cursor-shaders
GHOSTTY_CONFIG=~/.config/ghostty/config

if [[ -d "$GHOSTTY_SHADER_DIR" ]]; then
  rm -rf "$GHOSTTY_SHADER_DIR"
  ok "Ghostty cursor shader removed."
else
  warn "Ghostty cursor shader directory not found — skipping."
fi

if [[ -f "$GHOSTTY_CONFIG" ]]; then
  if grep -q "ghostty-cursor-shaders" "$GHOSTTY_CONFIG"; then
    sed -i '/# Cursor elastic animation shader/d' "$GHOSTTY_CONFIG"
    sed -i '/custom-shader = shaders\/ghostty-cursor-shaders/d' "$GHOSTTY_CONFIG"
    sed -i '/custom-shader-animation = always/d' "$GHOSTTY_CONFIG"
    ok "Ghostty config cleaned of cursor shader entries."
  else
    warn "No cursor shader entries found in Ghostty config."
  fi
else
  warn "Ghostty config not found — nothing to clean."
fi

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

# ════════════════════════════════════════════════════════════════
#  FULL CLEAN ONLY (mode 2)
# ════════════════════════════════════════════════════════════════

if [[ "$MODE" == "2" ]]; then

  log "Removing DNF packages (zsh, fzf, eza, neovim, git)..."
  warn "curl will NOT be removed as it is commonly used by other tools."
  sudo dnf remove -y zsh fzf eza neovim git
  sudo dnf autoremove -y
  ok "DNF packages removed."

  log "Removing ~/.zsh_history..."
  rm -f ~/.zsh_history
  ok "~/.zsh_history removed."

  log "Removing all .zshrc backups..."
  rm -f ~/.zshrc.backup.* ~/.zshrc.uninstall.*
  ok "All .zshrc backups removed."

fi

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}   Uninstall complete!${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "\n  Log out and back in to switch back to bash.\n"
