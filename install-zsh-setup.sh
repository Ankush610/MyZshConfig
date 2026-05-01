#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  install-zsh-setup.sh — Fedora 44 Zsh Environment Setup
#  Installs: zsh, fzf, lsd, bat, neovim, git,
#            zsh-syntax-highlighting, zsh-autosuggestions, fzf-tab
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

# ── Root check ───────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  err "Don't run this script as root. Run as your normal user — sudo will be used where needed."
fi

echo -e "\n${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Zsh Environment Setup — Fedora 44${RESET}"
echo -e "${BOLD}════════════════════════════════════════════════${RESET}\n"

# ── Internet check ───────────────────────────────────────────────
log "Checking internet connectivity..."
if ! curl -s --max-time 5 https://github.com > /dev/null; then
  err "No internet connection. Please connect and try again."
fi
ok "Internet connection OK."

# ── Sudo upfront ─────────────────────────────────────────────────
log "Requesting sudo access upfront..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ── 1. DNF packages ──────────────────────────────────────────────
log "Installing DNF packages..."
sudo dnf install -y zsh fzf lsd bat neovim git curl
ok "DNF packages installed."

# ── 2. zsh-syntax-highlighting ───────────────────────────────────
log "Installing zsh-syntax-highlighting..."
mkdir -p ~/.zsh
if [[ -d ~/.zsh/zsh-syntax-highlighting ]]; then
  warn "Already exists — pulling latest..."
  git -C ~/.zsh/zsh-syntax-highlighting pull --quiet
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
fi
ok "zsh-syntax-highlighting ready."

# ── 3. zsh-autosuggestions ───────────────────────────────────────
log "Installing zsh-autosuggestions..."
if [[ -d ~/.zsh/zsh-autosuggestions ]]; then
  warn "Already exists — pulling latest..."
  git -C ~/.zsh/zsh-autosuggestions pull --quiet
else
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi
ok "zsh-autosuggestions ready."

# ── 4. fzf-tab ───────────────────────────────────────────────────
log "Installing fzf-tab..."
mkdir -p ~/.oh-my-zsh/custom/plugins
if [[ -d ~/.oh-my-zsh/custom/plugins/fzf-tab ]]; then
  warn "Already exists — pulling latest..."
  git -C ~/.oh-my-zsh/custom/plugins/fzf-tab pull --quiet
else
  git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
fi
ok "fzf-tab ready."

# ── 5. Deploy .zshrc ─────────────────────────────────────────────
ZSHRC_SOURCE="$(dirname "$0")/.zshrc"
if [[ -f "$ZSHRC_SOURCE" ]]; then
  log "Deploying .zshrc..."
  if [[ -f ~/.zshrc ]]; then
    BACKUP=~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    cp ~/.zshrc "$BACKUP"
    warn "Existing .zshrc backed up to $BACKUP"
  fi
  cp "$ZSHRC_SOURCE" ~/.zshrc
  ok ".zshrc deployed."
else
  warn ".zshrc not found next to this script — skipping. Place .zshrc in the same folder."
fi

# ── 6. Change default shell ──────────────────────────────────────
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)
if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  ok "Default shell is already zsh."
else
  log "Changing default shell to zsh..."
  sudo chsh -s "$ZSH_PATH" "$USER"
  ok "Default shell changed to zsh."
fi

# ── 7. Verify installs ───────────────────────────────────────────
echo -e "\n${BOLD}── Verification ─────────────────────────────────${RESET}"
check() {
  if command -v "$1" &>/dev/null; then
    ok "$1 $(command -v $1)"
  else
    warn "$1 not found — something may have gone wrong"
  fi
}
check zsh
check fzf
check lsd
check bat
check nvim
check git
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && ok "zsh-syntax-highlighting plugin" || warn "zsh-syntax-highlighting plugin missing"
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]         && ok "zsh-autosuggestions plugin"    || warn "zsh-autosuggestions plugin missing"
[[ -f ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh ]]    && ok "fzf-tab plugin"                || warn "fzf-tab plugin missing"
[[ -f ~/.zshrc ]]                                                    && ok ".zshrc deployed"               || warn ".zshrc missing"

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}   Installation complete!${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "\n  ${BOLD}Next steps:${RESET}"
echo -e "  1. Run ${CYAN}exec zsh${RESET} to start zsh now"
echo -e "     OR log out and back in for permanent effect"
echo -e "  2. ${CYAN}Ctrl+R${RESET}        — fuzzy history search"
echo -e "  3. ${CYAN}Ctrl+F${RESET}        — fuzzy file finder"
echo -e "  4. ${CYAN}Tab${RESET}           — fuzzy tab completion"
echo -e "  5. ${CYAN}↑ / ↓${RESET}         — history prefix search"
echo -e "  6. ${CYAN}→ / Ctrl+Space${RESET} — accept autosuggestion\n"
