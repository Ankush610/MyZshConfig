# ════════════════════════════════════════════════════════════════
#  ~/.zshrc — Fedora / Ghostty + Dankshell
#  Colors come entirely from Ghostty (theme = dankcolors).
#  This file never touches TERM, LS_COLORS, or EZA_COLORS —
#  it just inherits whatever Ghostty sets in the environment.
# ════════════════════════════════════════════════════════════════

# ── Path ─────────────────────────────────────────────────────────
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
  PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# ── Zsh Options ──────────────────────────────────────────────────
setopt AUTO_CD
setopt CORRECT
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PROMPT_SUBST

# ── History ──────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ── Completion ───────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Inherit LS_COLORS set by Ghostty — do not override
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── fzf-tab ──────────────────────────────────────────────────────
source ~/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh 2>/dev/null || true

if command -v eza &>/dev/null; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --color=always --icons $realpath 2>/dev/null'
  # Directories preview with eza, files with bat
  zstyle ':fzf-tab:complete:*'    fzf-preview \
    'if [[ -d $realpath ]]; then eza --color=always --icons $realpath 2>/dev/null; else bat --color=always --style=numbers $realpath 2>/dev/null || echo $realpath; fi'
fi

# ── Zsh Syntax Highlighting ──────────────────────────────────────
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || \
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || true

# ── Zsh Autosuggestions ──────────────────────────────────────────
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || \
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || true

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── fzf ──────────────────────────────────────────────────────────
source /usr/share/fzf/shell/key-bindings.zsh 2>/dev/null || true
source /usr/share/fzf/shell/completion.zsh   2>/dev/null || true

# Remap fzf file finder: Ctrl+T is grabbed by Ghostty, use Ctrl+F instead
bindkey '^T' undefined-key
bindkey '^F' fzf-file-widget

# ── zoxide (smarter cd: z <partial-path>) ────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── Aliases ──────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --level=2 --icons'
alias la='eza -a --icons'
alias vi='nvim'
alias vim='nvim'
command -v bat  &>/dev/null && alias cat='bat --paging=never'
command -v glow &>/dev/null && alias md='glow -p'

alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias zshhelp='cat ~/.zsh/cheatsheet.txt 2>/dev/null || echo "cheatsheet not found — re-run install-zsh-setup.sh"'

# ── Git Aliases ──────────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# ── History Search (Arrow Keys) ──────────────────────────────────
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# ── Key Bindings ─────────────────────────────────────────────────
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H'      backward-kill-word

# ── Autosuggestion Bindings ──────────────────────────────────────
bindkey '^ '   autosuggest-accept
bindkey '^[f'  forward-word

# ── Prompt (ANSI slots → dankshell palette, updates with wallpaper)
autoload -Uz colors && colors
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{3}(%b)%f'
PROMPT="%F{2}[%n@%m]%f%F{4}%~%f\${vcs_info_msg_0_}%F{4}%#%f "

# ── Editors ──────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R'

# ── Ghostty cursor shader ────────────────────────────────────────
# Elastic animation is configured in ~/.config/ghostty/config.
# Managed by install-zsh-setup.sh — no sourcing needed here.
