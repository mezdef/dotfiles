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

## Setup

macOS or Linux. Windows runs the Linux setup inside WSL2; see [`docs/windows.md`](docs/windows.md).

`setup.sh` runs `brew bundle`, creates the directories apps write to, stows every package for the
OS, renders and loads the LaunchAgents on macOS, and installs the tmux plugins. It is safe to rerun.

### New machine

1. Install Homebrew from <https://brew.sh>. On Linux, install its prerequisites first and keep the
   default prefix, `/home/linuxbrew/.linuxbrew`, which `.zprofile` expects:

   ```sh
   sudo apt update && sudo apt install -y build-essential procps curl file git
   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
   ```

2. On the laptop only, never the mini (it runs media-server's `tools/syncthing/configure.sh`), copy
   `syncthing/.config/filesync/env.example` to `env` beside it (gitignored). `setup.sh` stows
   `syncthing` only when `env` sets `FILESYNC_CLIENT=1`; it shares every non-`_` dir in
   `~/Filesync` with the mini.
3. Clone colocated with jj and run setup. On Linux the Brewfile adds `zsh`, `git` and `jq` and
   skips kanata and the casks.

   ```sh
   brew install jj
   jj git clone --colocate git@github.com:mezdef/dotfiles.git ~/dotfiles
   ~/dotfiles/setup.sh
   ```

4. On Linux, make brew's zsh the login shell:

   ```sh
   command -v zsh | sudo tee -a /etc/shells
   chsh -s "$(command -v zsh)"
   ```

5. Create `.zprofile.local` and `.zshrc.local` if needed (see
   [Local Override Pattern](#local-override-pattern)), then open a new terminal.
6. atuin: `atuin login -u <user>`. The key comes from the old machine and is never committed.
7. Identity and secrets come from an overlay outside this repo. Git includes
   `~/.config/git/identity`, jj reads `~/.config/jj/conf.d/`, and `.zprofile` sources
   `~/.local/state/secrets.env`. Each is optional; without them, set `user.name` and `user.email`
   yourself.
8. macOS only:
   - kanata: install the daemon and grant Input Monitoring as in [`kanata/README.md`](kanata/README.md).
   - Run `~/.macos` for system defaults and `~/.local/share/nvim-opener/build.sh` for the
     NvimOpener app.
   - SwiftBar: set its plugin directory to `~/.config/swiftbar/plugins`.
   - Raycast: add `~/.local/bin` as a script directory.

### Existing machine

```sh
cd ~/dotfiles && jj git fetch && jj new master && ./setup.sh
```

LaunchAgents are not stowed. Their plists carry `@HOME@`, which `install-launchagent` renders into
`~/Library/LaunchAgents` before loading each one, so a changed plist needs `setup.sh` again.
`karabiner` is stowed only when `~/.config/karabiner/karabiner.json` is missing, because Karabiner
replaces the link with a file on save. `docs/` is not a package.

## Packages

| Package | What it configures |
|---------|--------------------|
| `atuin` | Shell history search (ctrl-r). History DB and sync key stay in `~/.local/share/atuin/`, untracked |
| `bat` | `bat` pager, Catppuccin Mocha theme |
| `ghostty` | Terminal; keybind remaps for tmux compatibility |
| `git` | `git/config` |
| `herdr` | Terminal multiplexer; keybinds mirror tmux, plus tab-name plugin |
| `jj` | Jujutsu VCS |
| `jjui` | Jujutsu TUI |
| `kanata` | Keyboard remapping: home row mods, hyper key, scroll. See `kanata/README.md` |
| `karabiner` | Not used for remapping — kept only for the DriverKit driver kanata needs |
| `macos` | System defaults (`.macos`), wallpaper scripts, nvim-opener, LaunchAgents |
| `nvim` | LazyVim-based Neovim config |
| `swiftbar` | Menu-bar plugins: unread mail count, now playing |
| `syncthing` | Laptop-only Filesync client: shares `~/Filesync` dirs with the mini. Device ID stays in a gitignored `env` |
| `tmux` | Multiplexer; prefix-less keybinds, helper scripts |
| `zsh` | Shell: `.zshenv`, `.zprofile`, `.zshrc`, prompt, theme, jj helpers |

`karabiner-ts/` (the old TypeScript karabiner generator) is gone — kanata replaced it.

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

Machine-specific config goes in untracked `.local` files:

| File | Purpose |
|------|---------|
| `~/.config/zsh/.zprofile.local` | Machine PATH (e.g. postgresql) |
| `~/.config/zsh/.zshrc.local` | Machine-specific aliases, interactive-only overrides |

These files are gitignored and must be created manually on each machine. Both are sourced automatically at the end of their respective rc files if they exist.
