#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  install-zsh-setup.sh — Fedora 44 Zsh Environment Setup
#  Installs: zsh, fzf, eza, neovim, git,
#            zsh-syntax-highlighting, zsh-autosuggestions, fzf-tab,
#            Ghostty cursor shader (elastic animation)
#
#  Run once manually: bash install-zsh-setup.sh
#  This script is NOT sourced by .zshrc — it is a one-time installer.
# ════════════════════════════════════════════════════════════════

set -e

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

LOG=/tmp/zsh-setup-install.log
: >"$LOG"

TOTAL=8
STEP=0

step() {
  STEP=$((STEP + 1))
  echo -e "\n${CYAN}${BOLD}[$STEP/$TOTAL]${RESET} ${BOLD}$1${RESET}"
}
ok() { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
err() {
  echo -e "  ${RED}✘${RESET}  $1"
  exit 1
}

# run <description> <command...>
# Runs the command quietly (output → $LOG) with a spinner; on failure
# prints the tail of the log and exits.
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
  if ((rc != 0)); then
    echo -e "  ${RED}✘${RESET}  $msg failed (exit $rc) — last lines of log:"
    tail -n 20 "$LOG" | sed 's/^/     /'
    err "Full log: $LOG"
  fi
}

# clone_or_update <repo-url> <target-dir>
clone_or_update() {
  local name
  name=$(basename "$2")
  if [[ -d "$2" ]]; then
    run "Updating $name" git -C "$2" pull --quiet
  else
    run "Cloning $name" git clone --depth 1 "$1" "$2"
  fi
}

# ── Root check ───────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  err "Don't run this script as root. Run as your normal user — sudo will be used where needed."
fi

echo -e "\n${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   Zsh Environment Setup — Fedora 44${RESET}"
echo -e "${BOLD}════════════════════════════════════════════════${RESET}\n"

# ── Internet check ───────────────────────────────────────────────
if ! curl -s --max-time 5 https://github.com >/dev/null; then
  err "No internet connection. Please connect and try again."
fi
ok "Internet connection OK."

# ── Sudo upfront ─────────────────────────────────────────────────
ok "Requesting sudo access upfront..."
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# ── 1. DNF packages ──────────────────────────────────────────────
# zsh      — the shell itself
# fzf      — fuzzy finder (Ctrl+F, Ctrl+R, fzf-tab previews)
# eza      — modern ls replacement (ls/ll/lt/la aliases in .zshrc)
# neovim   — editor (vi/vim aliases, $EDITOR/$VISUAL in .zshrc)
# git      — version control (git aliases + used to clone plugins below)
# curl     — used by this script for internet check
step "DNF packages"
run "Installing zsh fzf eza neovim git curl" \
  sudo dnf install -y zsh fzf eza neovim git curl
ok "DNF packages installed."

# ── 2. zsh-syntax-highlighting ───────────────────────────────────
step "zsh-syntax-highlighting"
mkdir -p ~/.zsh
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
ok "zsh-syntax-highlighting ready."

# ── 3. zsh-autosuggestions ───────────────────────────────────────
step "zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
ok "zsh-autosuggestions ready."

# ── 4. fzf-tab ───────────────────────────────────────────────────
step "fzf-tab"
mkdir -p ~/.oh-my-zsh/custom/plugins
clone_or_update https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
ok "fzf-tab ready."

# ── 5. Ghostty cursor shader (elastic animation) ─────────────────
step "Ghostty cursor shader"
GHOSTTY_SHADER_DIR=~/.config/ghostty/shaders
GHOSTTY_CONFIG=~/.config/ghostty/config

mkdir -p "$GHOSTTY_SHADER_DIR"
clone_or_update https://github.com/sahaj-b/ghostty-cursor-shaders \
  "$GHOSTTY_SHADER_DIR/ghostty-cursor-shaders"
ok "Ghostty cursor shader cloned."

# ── 6. Ghostty config ────────────────────────────────────────────
step "Ghostty config"
mkdir -p ~/.config/ghostty
touch "$GHOSTTY_CONFIG"
if ! grep -qF "ghostty-cursor-shaders/cursor_tail.glsl" "$GHOSTTY_CONFIG"; then
  echo "" >>"$GHOSTTY_CONFIG"
  echo "# Cursor elastic animation shader" >>"$GHOSTTY_CONFIG"
  echo "custom-shader = shaders/ghostty-cursor-shaders/cursor_tail.glsl" >>"$GHOSTTY_CONFIG"
  echo "custom-shader-animation = always" >>"$GHOSTTY_CONFIG"
  ok "Ghostty config updated with cursor shader."
else
  ok "Ghostty config already has cursor shader entry."
fi

# ── 7. Deploy .zshrc ─────────────────────────────────────────────
step "Deploy dankshell config"
ZSHRC_SOURCE="$(dirname "$0")/.zshrc"
DANKSHELL_FILE=~/.zsh/dankshell.zsh
SOURCE_LINE="source ~/.zsh/dankshell.zsh"

if [[ -f "$ZSHRC_SOURCE" ]]; then
  # Install config as a separate sourceable file
  mkdir -p ~/.zsh
  cp "$ZSHRC_SOURCE" "$DANKSHELL_FILE"
  ok "Dankshell config installed to $DANKSHELL_FILE"

  if [[ ! -f ~/.zshrc ]]; then
    # No existing .zshrc — create a minimal one
    echo "$SOURCE_LINE" >~/.zshrc
    ok ".zshrc created."
  elif grep -qF "$SOURCE_LINE" ~/.zshrc; then
    # Already hooked in — just update the sourced file (already done above)
    ok ".zshrc already sources dankshell — config updated in place."
  else
    # Existing .zshrc found — append the source line
    echo "" >>~/.zshrc
    echo "# ── Dankshell config (added by install-zsh-setup.sh) ────────────" >>~/.zshrc
    echo "$SOURCE_LINE" >>~/.zshrc
    ok "Dankshell config appended to your existing .zshrc."

    echo ""
    warn "Your existing .zshrc was NOT replaced — your config is intact."
    warn "The dankshell config was appended at the bottom, so it takes"
    warn "precedence over any conflicting aliases or settings above it."
    warn "If you want to override anything (aliases, keybindings, etc.),"
    warn "add your overrides AFTER the source line in ~/.zshrc, or edit"
    warn "~/.zsh/dankshell.zsh directly."
    echo ""
  fi
else
  warn ".zshrc not found next to this script — skipping. Place .zshrc in the same folder."
fi

# ── 8. Change default shell ──────────────────────────────────────
step "Default shell"
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(command -v zsh)
if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
  ok "Default shell is already zsh."
else
  sudo chsh -s "$ZSH_PATH" "$USER"
  ok "Default shell changed to zsh."
fi

# ── Verify installs ──────────────────────────────────────────────
echo -e "\n${BOLD}── Verification ─────────────────────────────────${RESET}"
check() {
  if command -v "$1" &>/dev/null; then
    ok "$1 $(command -v "$1")"
  else
    warn "$1 not found — something may have gone wrong"
  fi
}
check zsh
check fzf
check eza
check nvim
check git
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  ok "zsh-syntax-highlighting plugin" || warn "zsh-syntax-highlighting plugin missing"
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  ok "zsh-autosuggestions plugin" || warn "zsh-autosuggestions plugin missing"
[[ -f ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh ]] &&
  ok "fzf-tab plugin" || warn "fzf-tab plugin missing"
[[ -f ~/.config/ghostty/shaders/ghostty-cursor-shaders/cursor_tail.glsl ]] &&
  ok "Ghostty cursor shader" || warn "Ghostty cursor shader missing"
[[ -f ~/.zshrc ]] &&
  ok ".zshrc deployed" || warn ".zshrc missing"

# ── Cheatsheet ───────────────────────────────────────────────────
# Written to ~/.zsh/cheatsheet.txt so the `zshhelp` alias can reprint it.
CHEATSHEET=$(
  cat <<EOF

${BOLD}──────────────────────────────────────────────────────────────${RESET}
 ${BOLD}INSTALLED COMPONENTS${RESET}
${BOLD}──────────────────────────────────────────────────────────────${RESET}
  ${CYAN}zsh${RESET}                      default shell, git-aware prompt: [user@host]~/path (branch)
  ${CYAN}zsh-syntax-highlighting${RESET}  commands turn green (valid) / red (invalid) as you type
  ${CYAN}zsh-autosuggestions${RESET}      grey ghost-text suggestions from your history
  ${CYAN}fzf + fzf-tab${RESET}            fuzzy history/file search, fuzzy Tab completion with previews
  ${CYAN}eza${RESET}                      modern ls with icons (ls/ll/la/lt aliases)
  ${CYAN}neovim${RESET}                   default editor (\$EDITOR/\$VISUAL, vi/vim aliases)
  ${CYAN}Ghostty cursor shader${RESET}    elastic cursor animation

${BOLD}──────────────────────────────────────────────────────────────${RESET}
 ${BOLD}KEYBINDINGS${RESET}
${BOLD}──────────────────────────────────────────────────────────────${RESET}
  ${CYAN}Ctrl+R${RESET}           fuzzy search command history
  ${CYAN}Ctrl+F${RESET}           fuzzy find files (inserts path at cursor)
  ${CYAN}Tab${RESET}              fuzzy completion menu with directory preview
  ${CYAN}↑ / ↓${RESET}            search history filtered by what you've typed
  ${CYAN}→ / Ctrl+Space${RESET}   accept the grey autosuggestion
  ${CYAN}Alt+F${RESET}            accept autosuggestion one word at a time
  ${CYAN}Ctrl+← / Ctrl+→${RESET}  jump backward / forward one word
  ${CYAN}Ctrl+Backspace${RESET}   delete the previous word

${BOLD}──────────────────────────────────────────────────────────────${RESET}
 ${BOLD}ALIASES${RESET}
${BOLD}──────────────────────────────────────────────────────────────${RESET}
  ${CYAN}ls / la${RESET}          list files / incl. hidden (icons)
  ${CYAN}ll${RESET}               long listing incl. hidden
  ${CYAN}lt${RESET}               tree view, 2 levels deep
  ${CYAN}vi / vim${RESET}         open neovim
  ${CYAN}.. / ...${RESET}         up one / two directories
  ${CYAN}cp / mv / rm${RESET}     interactive + verbose (asks before overwrite/delete)
  ${CYAN}mkdir${RESET}            creates parent dirs automatically (-pv)
  ${CYAN}grep / df / du${RESET}   colored / human-readable sizes
  ${CYAN}zshhelp${RESET}          show this cheatsheet again

  ${BOLD}Git:${RESET}  ${CYAN}gs${RESET} status   ${CYAN}ga${RESET} add   ${CYAN}gc${RESET} commit   ${CYAN}gp${RESET} push   ${CYAN}gd${RESET} diff   ${CYAN}gl${RESET} pretty log

${BOLD}──────────────────────────────────────────────────────────────${RESET}
 ${BOLD}SHELL BEHAVIOR${RESET}
${BOLD}──────────────────────────────────────────────────────────────${RESET}
  • Type a directory name alone to cd into it (auto-cd)
  • Mistyped a command? zsh offers a spelling correction
  • History is shared live across all open terminals (duplicates skipped)
  • Start a command with a space to keep it out of history
  • Every cd is pushed to the dir stack: ${CYAN}dirs -v${RESET} to list, ${CYAN}cd -2${RESET} to jump back

EOF
)
mkdir -p ~/.zsh
echo -e "$CHEATSHEET" >~/.zsh/cheatsheet.txt

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}   Installation complete!${RESET}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${RESET}"
echo -e "\n  ${BOLD}Next steps:${RESET}"
echo -e "  1. Run ${CYAN}exec zsh${RESET} to start zsh now"
echo -e "     OR log out and back in for permanent effect"
echo -e "  2. Reload Ghostty config to activate cursor shader:"
echo -e "     ${CYAN}systemctl reload --user app-com.mitchellh.ghostty.service${RESET}"

cat ~/.zsh/cheatsheet.txt
echo -e "\n  View this cheatsheet anytime with: ${CYAN}zshhelp${RESET}"
echo -e "  Install log: ${CYAN}$LOG${RESET}\n"
