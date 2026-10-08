# Dotfiles

GNU Stow-managed dotfiles. Each top-level directory is a stow package that symlinks into `$HOME`.
`.stowrc` sets `--target=~/`. From the repo root: `stow <package>`.

See `README.md` for the package inventory and the `.local` override pattern.

**A machine is set up by `setup.sh`, never by hand-run stow commands.** It is idempotent, so an
existing machine reruns it. A new package or target directory goes into it, and the README's Setup
section lists only the steps it cannot do.

## Commits

Conventional commits: `type(scope): imperative summary`, first line at most 72 characters.

- `type` is `feat`, `fix`, `test`, `refactor` or `docs`, and no others.
- `scope` is free-form and lowercase, naming the area touched. A stow package name is the usual
  one.
- A change in progress is described `wip - <description>` and is never pushed.
- No commit carries a `Co-Authored-By` trailer, whoever wrote it.

Nothing enforces it. This section is the record.

## Karabiner


**Not used for remapping** — kanata does that. Karabiner-Elements must stay installed only
because kanata depends on its **Karabiner-DriverKit-VirtualHIDDevice** driver. The package
exists to preserve `karabiner.json` so Karabiner doesn't prompt for setup on launch.

Do not add remapping rules here. See `karabiner/README.md`.

## Package notes

Every other package keeps its own rules in a `CLAUDE.md` beside it, which costs nothing at startup
and loads when a file in that directory is read: `kanata/`, `zsh/`, `atuin/`, `ghostty/`, `tmux/`,
`herdr/`.

Three rules stay here, because each one has to fire before its package is opened:

- **Keyboard remapping is kanata's, not karabiner's.** Detail in `kanata/CLAUDE.md`.
- **A zsh tool init goes through `_cache_init`** (`.zshrc:31`) or it costs ~10ms per shell.
- **Atuin's `key` is a secret** and `history.db` is machine state. Both live in
  `~/.local/share/atuin/` and are deliberately not version controlled.
