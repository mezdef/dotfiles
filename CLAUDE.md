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

## Ghostty (terminal)

Config: `ghostty/.config/ghostty/config`. Includes keybind remaps for tmux compatibility (ctrl+/, ctrl+\, ctrl+backspace send specific byte sequences).

## Tmux

Config: `tmux/.config/tmux/tmux.conf`. Prefix-less keybindings for common actions (splits, copy mode, plugins).
