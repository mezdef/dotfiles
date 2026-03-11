# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Stow Setup

Each top-level directory is a stow package. From the repo root:

```sh
stow zsh       # symlinks zsh/ contents into ~/
stow nvim      # symlinks nvim/ contents into ~/
# etc.
```

`.stowrc` sets `--target=~/` so all packages target `$HOME`.

Stow mirrors the directory structure inside each package into the target. To get a symlink at
`~/.config/tmux/tmux.conf`, the file must live at `dotfiles/tmux/.config/tmux/tmux.conf` —
stow strips the package directory (`tmux/`) and recreates everything beneath it relative to `~/`.

## Zsh

```
~/.zshenv                        → sets ZDOTDIR=$HOME/.config/zsh (only)
~/.config/zsh/.zprofile          → PATH, .zprofile.local
~/.config/zsh/.zshrc             → history, plugins, prompt, vi mode, aliases, source .zshrc.local
```

- `.zprofile` runs once at login — exported env vars are inherited by all child processes
- `.zshrc` runs for every interactive shell — tool inits (zoxide, fzf, carapace) live here

## Local Override Pattern

Machine-specific config and secrets go in untracked `.local` files:

| File | Purpose |
|------|---------|
| `~/.config/zsh/.zprofile.local` | Machine PATH (e.g. postgresql), secrets (DATABASE_URL, tokens), credentials |
| `~/.config/zsh/.zshrc.local` | Machine-specific aliases, interactive-only overrides |

These files are gitignored and must be created manually on each machine. Both are sourced automatically at the end of their respective rc files if they exist.
