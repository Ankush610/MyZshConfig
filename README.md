# MyZshConfig

A zsh setup for Fedora — eza, bat, fzf + fzf-tab, zoxide, neovim, syntax
highlighting and autosuggestions — installed, updated, uninstalled and
repaired by one script.

```bash
git clone <this repo> && cd MyZshConfig
./dankshell
```

That opens a menu. Arrow keys or `j`/`k`, Enter to pick, `q` to quit.

```
  Install / update
  Uninstall — config only (keep packages)
  Uninstall — everything (also remove packages we installed)
  Doctor  (find & fix broken aliases)
  Status
  Quit
```

Everything is also available non-interactively:

| Flag | What it does |
|---|---|
| `--install` | Install or update. Safe to re-run. |
| `--uninstall` | Remove config and plugins, revert to bash, keep packages. |
| `--uninstall-full` | Also remove the packages dankshell installed. |
| `--doctor` | Find and fix aliases pointing at missing commands. |
| `--status` | Report what is installed and what is not. |
| `--yes` | Don't prompt. Combine with any of the above. |

## Files

| File | Role |
|---|---|
| `dankshell` | The whole tool: install, uninstall, doctor, status. |
| `dankshell.zsh` | The zsh config, installed to `~/.zsh/dankshell.zsh`. |
| `dankshell.bash` | The bash-safe subset, installed to `~/.zsh/dankshell.bash`. |

`dankshell.zsh` is **not** a `~/.zshrc` — don't copy it over one. It is a
fragment that your `~/.zshrc` sources from inside a marked block:

```
# >>> dankshell >>>
[ -f "$HOME/.zsh/dankshell.zsh" ] && . "$HOME/.zsh/dankshell.zsh"
# <<< dankshell <<<
```

Your own config above and below that block is left alone. Re-running the
installer replaces the block rather than appending a second one.

## Why bash gets a config too

The bug that prompted this rewrite: after uninstalling, every new terminal
answered `ls`, `vi` and `cat` with *"Install package 'eza'?"*.

The cause was aliases in `~/.bashrc` — `alias ls='eza --icons'`,
`alias vi="nvim"` — that the old uninstaller never knew about. It reverted
the login shell to bash and removed eza and neovim in the same run, so the
next bash shell started up full of aliases pointing at deleted binaries, and
Fedora's `PackageKit-command-not-found` offered to reinstall each one.

Two things prevent it now:

1. **Every alias is guarded.** `dankshell.zsh` and `dankshell.bash` define
   `ls` only when eza is actually installed. A missing tool means no alias
   and the real command back, never a package prompt.
2. **Both shells are managed.** Install writes a block to `~/.bashrc` as well
   as `~/.zshrc`, and uninstall removes both. Loose unguarded aliases found
   outside the block are reported and, with your OK, commented out.

## Doctor

`./dankshell --doctor` reads `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`,
`~/.zprofile`, `~/.profile` and `~/.bashrc.d/*` and reports two things:

- **Broken** — an alias or `eval "$(tool …)"` whose command is not installed.
  These are actively breaking your shell right now.
- **Stray** — an unguarded alias that duplicates one dankshell provides. It
  works today and breaks the day the tool is removed.

Nothing is changed without a prompt. Fixing means prefixing the line with
`# dankshell: disabled, …`, so the original is still there to uncomment, and
the file is backed up first. Lines already guarded with `command -v` and
lines already commented out are skipped.

If doctor flags an alias for a command that lives in an environment it can't
see — a conda env, a direnv shim — say no. It only looks at `$PATH`.

## Uninstall only removes what it installed

Install records what it actually did in
`~/.local/share/dankshell/manifest`:

```
pkg   eza
file  /home/you/.zsh/dankshell.zsh
dir   /home/you/.zsh/fzf-tab
rc    /home/you/.zshrc
```

A package is recorded only if `rpm -q` says it was **absent** before install.
Anything already on the machine — most people's `git` and `curl` — is never
recorded and so can never be removed. Uninstall works from that list; it has
no hardcoded package names.

Removal uses `--setopt=clean_requirements_on_remove=False`. Without it, a
plain `dnf remove` of these eight packages also sweeps up every dependency
that becomes orphaned — measured on a clean Fedora 44 container, **143
packages instead of 9**. On the machine this was first hit, it took out
`nodejs22`, `ripgrep`, `xsel` and `tree-sitter-cli`.

## Backups

Every file dankshell edits is copied to
`~/.local/share/dankshell/backups/<name>.<timestamp>` first. **Uninstall
never deletes them** — it prints the directory when it finishes.

## Keybindings and aliases

Run `zshhelp` for the cheatsheet, or read
`~/.zsh/cheatsheet.txt`.

## Scope

Fedora only (`dnf`, `rpm`). No `dialog`/`whiptail` dependency — the menu is
plain bash, so it works before anything is installed.
