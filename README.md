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

## Packages

| Package | What it configures |
|---------|--------------------|
| `atuin` | Shell history search (ctrl-r). History DB and sync key stay in `~/.local/share/atuin/`, untracked |
| `bat` | `bat` pager, Catppuccin Mocha theme |
| `claude` | Claude Code: `CLAUDE.md`, hooks, skills, output styles, settings |
| `ghostty` | Terminal; keybind remaps for tmux compatibility |
| `git` | `git/config` |
| `herdr` | Terminal multiplexer; keybinds mirror tmux, plus tab-name plugin |
| `jj` | Jujutsu VCS |
| `jjui` | Jujutsu TUI |
| `kanata` | Keyboard remapping: home row mods, hyper key, scroll. See `kanata/README.md` |
| `karabiner` | Not used for remapping — kept only for the DriverKit driver kanata needs |
| `macos` | System defaults (`.macos`), wallpaper scripts, nvim-opener, LaunchAgents |
| `nvim` | LazyVim-based Neovim config |
| `sesh` | Session manager |
| `starship` | Prompt config — **currently inactive**, `.zshrc` uses `prompt.zsh` instead |
| `tmux` | Multiplexer; prefix-less keybinds, helper scripts |
| `zsh` | Shell: `.zshenv`, `.zprofile`, `.zshrc`, prompt, theme, jj helpers |

`raycast/` is gitignored. `karabiner-ts/` (the old TypeScript karabiner generator) is gone — kanata replaced it.

## Zsh

```
~/.zshenv                        → sets ZDOTDIR=$HOME/.config/zsh (only)
~/.config/zsh/.zprofile          → PATH, .zprofile.local
~/.config/zsh/.zshrc             → history, plugins, prompt, vi mode, aliases, source .zshrc.local
~/.config/zsh/prompt.zsh         → prompt symbol, directory, cmd duration, vi cursor
~/.config/zsh/theme.zsh          → catppuccin colors
~/.config/zsh/jj.zsh             → jjw workspace helper
```

- `.zprofile` runs once at login — exported env vars are inherited by all child processes
- `.zshrc` runs for every interactive shell — tool inits (zoxide, fzf, carapace, atuin) live here
- Tool inits go through `_cache_init`, which caches init output to `~/.cache/zsh/` so later
  shells source a file instead of forking the command. Use it for any new tool init.
- `rr` clears that cache and reloads the shell

## Local Override Pattern

Machine-specific config and secrets go in untracked `.local` files:

| File | Purpose |
|------|---------|
| `~/.config/zsh/.zprofile.local` | Machine PATH (e.g. postgresql), secrets (DATABASE_URL, tokens), credentials |
| `~/.config/zsh/.zshrc.local` | Machine-specific aliases, interactive-only overrides |

These files are gitignored and must be created manually on each machine. Both are sourced automatically at the end of their respective rc files if they exist.
