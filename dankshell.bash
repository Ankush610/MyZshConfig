# ════════════════════════════════════════════════════════════════
#  dankshell.bash — sourced from ~/.bashrc by the `dankshell` tool.
#
#  The bash-safe subset of dankshell.zsh: aliases and fzf keybinds,
#  no zsh widgets. Its whole job is to make sure that when you are
#  in bash — including right after uninstalling zsh — `ls`, `vi` and
#  `cat` still work.
#
#  Every alias is guarded by `command -v`, so a missing tool means
#  the alias is not defined and you get the real command back,
#  never "Install package 'eza'?".
# ════════════════════════════════════════════════════════════════

if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -la --icons'
  alias lt='eza --tree --level=2 --icons'
  alias la='eza -a --icons'
fi
if command -v nvim &>/dev/null; then
  alias vi='nvim'
  alias vim='nvim'
  export EDITOR='nvim'
  export VISUAL='nvim'
fi
command -v bat  &>/dev/null && alias cat='bat --plain --paging=never'
command -v glow &>/dev/null && alias md='glow -p'

alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias zshhelp='command cat ~/.zsh/cheatsheet.txt 2>/dev/null || echo "cheatsheet not found — re-run dankshell"'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

command -v fzf    &>/dev/null && eval "$(fzf --bash)" 2>/dev/null
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

export PAGER='less'
export LESS='-R'
