# MyZshConfig

My personal Zsh setup for Fedora, built for a **Niri + Dank Material Shell + Ghostty** desktop. Colors are inherited entirely from Ghostty (dankcolors theme), so the shell follows the wallpaper-driven Dank Material Shell palette automatically.

## What's inside

| File | Purpose |
|------|---------|
| `.zshrc` | The actual shell config (installed as `~/.zsh/dankshell.zsh`) |
| `install-zsh-setup.sh` | One-time installer — packages, plugins, config, shader |
| `uninstall-zsh-setup.sh` | Reverts everything back to bash |

## What it sets up

- **Packages** (dnf): zsh, fzf, eza, neovim, git, zoxide (smarter `cd` — `z <partial-path>`), bat (syntax-highlighted `cat`), glow (markdown reader — `md file.md`)
- **Plugins**: zsh-syntax-highlighting, zsh-autosuggestions, fzf-tab (eza previews for dirs, bat previews for files)
- **Ghostty**: elastic cursor-tail shader, wired into `~/.config/ghostty/config`
- **Shell config**: sensible options, shared history, git-aware prompt using ANSI palette slots (so it recolors with the wallpaper), eza/nvim/git aliases, fzf keybindings (`Ctrl+F` file finder, since Ghostty grabs `Ctrl+T`)
- **Cheatsheet**: `zshhelp` prints a quick reference anytime

## Install

```bash
git clone https://github.com/Ankush610/MyZshConfig
cd MyZshConfig
bash install-zsh-setup.sh
```

The installer copies the config to `~/.zsh/dankshell.zsh` and sources it from `~/.zshrc` — an existing `.zshrc` is appended to, never replaced. It then sets zsh as the default shell. Log out and back in (or open a new Ghostty window) to start using it.

## Uninstall

```bash
bash uninstall-zsh-setup.sh              # configs + plugins, keep packages
bash uninstall-zsh-setup.sh --full       # also remove packages, history, backups
```
