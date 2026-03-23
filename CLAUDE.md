# Dotfiles

GNU Stow-managed dotfiles. Each top-level directory is a stow package that symlinks into `$HOME`.

## Karabiner (keyboard remapping)

Source of truth is TypeScript in `karabiner-ts/`, which generates `karabiner/.config/karabiner/karabiner.json`.

**To edit karabiner config:**
1. Edit files in `karabiner-ts/src/rules/`
2. Run `cd karabiner-ts && npm run build` (writes to `karabiner/.config/karabiner/karabiner.json`)
3. Run `stow --adopt karabiner` from dotfiles root (or `./karabiner-ts/scripts/deploy.sh` for both steps)

**Do NOT edit `karabiner.json` directly** — it is generated and will be overwritten.

`npm run dry-run` prints the config to stdout without writing.

Key files:
- `karabiner-ts/src/index.ts` — entry point, parameters, profile output
- `karabiner-ts/src/rules/home-row-mods.ts` — simultaneous combos, hold-for-mod, timing docs
- `karabiner-ts/src/rules/hyper-key.ts` — caps lock → hyper
- `karabiner-ts/src/rules/spotlight.ts` — cmd+space → hyper+space

## Kanata (keyboard remapping)

Replaces Karabiner for home row mods, hyper key, and spotlight remap. Config is `.kbd` files in `kanata/.config/kanata/`.

**To edit:** modify `.kbd` files — `live-reload yes` picks up changes automatically.

Key files:
- `kanata/.config/kanata/kanata.kbd` — entry point, defcfg, includes
- `kanata/.config/kanata/home-row-mods.kbd` — per-finger timing, typing layer, spotlight
- `kanata/.config/kanata/hyper.kbd` — caps lock → hyper

LaunchDaemon (`com.jtroo.kanata.plist`) is installed to `/Library/LaunchDaemons/` via `sudo ./kanata/scripts/install-daemon.sh`. The plist is version-controlled in `kanata/` but excluded from stow.

See `kanata/README.md` for setup, daemon management, and rollback.

## Ghostty (terminal)

Config: `ghostty/.config/ghostty/config`. Includes keybind remaps for tmux compatibility (ctrl+/, ctrl+\, ctrl+backspace send specific byte sequences).

## Tmux

Config: `tmux/.config/tmux/tmux.conf`. Prefix-less keybindings for common actions (splits, copy mode, plugins).
