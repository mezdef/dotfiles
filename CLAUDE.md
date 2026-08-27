# Dotfiles

GNU Stow-managed dotfiles. Each top-level directory is a stow package that symlinks into `$HOME`.
`.stowrc` sets `--target=~/`. From the repo root: `stow <package>`.

See `README.md` for the package inventory and the `.local` override pattern.

## Claude Code

Package root is `claude/.claude/`. Stow symlinks each entry into `~/.claude/`:
`settings.json`, `settings.local.json`, `CLAUDE.md`, `hooks/`, `skills/`, `scripts/`,
`output-styles/`, `statusline.sh`. Everything else under `~/.claude/` (`plans/`, `projects/`,
`sessions/`, `history.jsonl`, caches) is machine state and stays untracked.

Work-specific skills and scripts physically live in the package but are gitignored, so they are
stowed locally without being published. See the gitignore block for the list.

### Settings

`settings.json` is verified against Claude Code 2.1.228. Confirm a key exists before adding it,
rather than trusting a docs summary: `strings -a $(readlink -f $(which claude)) | grep -x '<key>'`.
The binary embeds the full settings-key list with descriptions, which is the fastest reference.

`outputStyle: "Direct"` activates `output-styles/direct.md`. Its register rules overlap the
Communication section of `claude/.claude/CLAUDE.md`; both load every turn, so if that duplication
becomes a problem, one of the two should own register.

Rules are evaluated `deny` -> `ask` -> `allow`, first match wins, and specificity does not change
that order. A deny rule therefore cannot carry allowlist exceptions, so deny rules must be narrow.

The split here is narrow-deny layered under broad-ask:

- `deny` holds only material with no legitimate read: the atuin sync key, `~/.aws/credentials`, and
  SSH private keys by name (`id_rsa*`, `id_ed25519*`, `id_ecdsa*`, `id_dsa*`). Deny never prompts
  and has no settings override, so nothing goes here that a real task might need.
- `ask` holds everything worth a confirmation but plausibly needed: `~/.ssh/**` and `~/.aws/**`
  broadly (so `config` and `known_hosts` prompt rather than fail), the `.env` family, `*.pem` and
  `*.key`, and force-push.

The layering works because deny is checked first: `~/.ssh/id_ed25519` is denied while
`~/.ssh/config` falls through to the broad ask. Do not duplicate an entry into both arrays — the
`ask` copy is dead.

The `.env` rules name specific files rather than globbing `**/.env*`, so `.env.example` stays
readable. `jj git push` does not match the `git push --force` rules; they only bite on raw git.

Both tiers are `Read(...)`/`Bash(...)` scoped. The allowlist grants `Bash(cat:*)`, `Bash(tail:*)`,
`Bash(grep:*)` and `Bash(find:*)`, any of which reaches a protected path without matching a rule.
Treat this as a guardrail against touching a secret by accident, not a security boundary. Closing
the Bash route needs `sandbox`, not more patterns — per-command patterns like `Bash(cat .env:*)`
miss `./.env`, `apps/x/.env` and every other spelling, so they imply coverage they lack.

Auto mode already runs 65 classifier `soft_deny` rules covering this ground independently, incl.
`Credential Exploration`, `Sensitive-Source Provenance` and `Credential Leakage`. Inspect them with
`claude auto-mode defaults` and see the effective config with `claude auto-mode config`.

#### What the allowlist buys under `defaultMode: auto`

Unmatched calls are reviewed by the classifier, not surfaced as a prompt. Allow rules therefore
reduce classifier round-trips and false positives, not prompt count. The false positives are real:
the classifier blocked three legitimate edits to this settings file while it was being written.

The allowlist was derived from usage, not guesswork: scan `~/.claude/projects/*/*.jsonl` for
`tool_use` entries, strip heredoc bodies (otherwise embedded script and SQL text counts as
commands), split compound commands on `|`/`&&`/`;`, strip env assignments and `sudo`/`timeout`,
then normalise to command + subcommand. 50 transcripts covered 9,046 Bash calls.

`jj` is the reason the list is long. Claude Code ships read-only handling for `git`, `gh` and
`docker` subcommands but has no concept of `jj`, so every jj call needs an explicit rule. The rules
are listed per-subcommand rather than as `Bash(jj:*)` or `Bash(jj file:*)` so that mutating
siblings stay uncovered: `jj file untrack` is not covered by `jj file show`/`file list`, and
**`jj git push` is deliberately absent** — it is the one jj operation with externally visible
effect, so it should keep being classified. Local jj mutations are allowlisted because the op log
makes them reversible via `jj undo` / `jj op restore`. Current coverage is 99% of observed jj calls.

MCP allow rules must match the real server name. `mcp__linear__*` sat in this file matching nothing
for months, because the server is actually `linear-server`. Verify against
`jq -r '[.projects[]?.mcpServers // {} | keys[]] | unique[]' ~/.claude.json` before adding a rule.

`Bash(bunx:*)`, `Bash(bun run:*)`, `Bash(curl:*)`, `Bash(gh api:*)`, `Bash(rm:*)` and
`Bash(chmod:*)` are deliberately broad, which is the reason the `Read` deny/ask tiers above are
advisory rather than binding. Narrower observed-usage replacements, if that trade is ever revisited:
`bunx vitest run` 917, `bunx eslint` 387, `bunx playwright` 30, `bunx prettier` 23; `bun run type`
741, `bun run lint` 171, `bun run test:unit` 54.

Never allowlist: `tmux send-keys` (injects keystrokes into any pane — arbitrary command execution
laundered through tmux), `psql` (arbitrary SQL and DDL), or interpreter wildcards. `Bash(python3:*)`
and `Bash(node:*)` were removed for exactly that reason — `python3 -c "print(open('.env').read())"`
reads a denied path without ever evaluating a `Read` rule.

Unresolved: the documented set of commands Claude Code auto-allows without any rule could only be
partly confirmed against 2.1.228. The `READONLY_COMMANDS` cluster is in the binary (`echo`,
`printf`, `grep`, `head`, `tail`, `stat`, `strings`, `uname`, `which`, `diff`, `sleep`, `cd`, `ls`,
`find`, `jq`, `pwd`, `whoami`), but `shortlog`, `reflog` and `blame` appear nowhere, so the claimed
built-in git/gh read-only lists are unverified here. Do not prune the `git diff` / `git log` /
`gh pr view` / `cat` / `ls` entries as redundant on that basis — test empirically first (remove one,
restart, run the command, see whether it is classified).

**Version lag.** Installed via Homebrew cask, which trails npm by roughly 15-20 versions
(2.1.228 installed / 2.1.231 cask / 2.1.247 npm as of 2026-08-27). `autoUpdates: true` has no
effect on a cask install; upgrade with `brew upgrade --cask claude-code`. Settings gated behind
the lag and therefore not yet usable: `promptCacheTtl` and `subagentPromptCacheTtl` (2.1.243),
`modelPicker` (2.1.243), `spellcheck` (2.1.235), `keybindingFlavor` (2.1.238).

### MCP servers

`.mcp.json` at the repo root defines this repo's servers and is tracked. Everything else lives
per-project in the untracked 142KB `~/.claude.json`, so it is not version controlled and has
drifted: the `work-app` worktrees disagree on the Linear server name (`lienar-server` is
a typo, and `-2`/`-4` define both `linear` and `linear-server`). Clean that up in those repos with
their own `.mcp.json`.

Adding a server to a tracked `.mcp.json` requires a one-time approval prompt on next start.

### Hooks

- `agent-finish.sh` — Stop event, `asyncRewake: true`. Runs `bun lint --fix` then `bun type` in
  node projects. **Contract: exit 2 with findings on stderr to wake Claude, exit 0 to stay
  silent.** Plain stdout at exit 0 is discarded by Claude Code, so anything meant for the model
  must go to stderr with exit 2.
- `plan-lifecycle-hook.sh` — PostToolUse, `matcher: "ExitPlanMode|Write|Edit"`. Emits reminders as
  `hookSpecificOutput.additionalContext` JSON, since PostToolUse also discards plain stdout.

Two rules learned the hard way:

1. **Never give a Stop hook a `timeout` shorter than the work it runs.** A cancelled hook has its
   output discarded, and a cancelled `eslint --cache` never writes `.eslintcache`, so every run
   stays cold forever. Cold eslint in `work-app` is ~68s against a 60s timeout; it never
   converged and blocked every turn end.
2. **Do slow post-turn work with `asyncRewake`, not a synchronous Stop hook.** It runs detached and
   only interrupts on failure.

`agent-finish.sh` takes a per-worktree `mkdir` lock, because `eslint --cache` and
`tsc --incremental` share mutable state across concurrent sessions in the same tree.

### Statusline

`statusline.sh` renders on every prompt, so it uses one `jq` fork and bash integer comparison. Do
not add per-render subprocesses.

## Kanata (keyboard remapping)

Handles home row mods, hyper key, spotlight remap, and scroll bindings. Config is `.kbd` files
in `kanata/.config/kanata/`.

**To edit:** modify `.kbd` files, then restart kanata: `sudo launchctl kickstart -k system/com.jtroo.kanata`

Key files (all included from `kanata.kbd`):
- `kanata.kbd` — entry point, defcfg, defsrc, includes
- `hyper.kbd` — caps lock → hyper (ctrl+opt+cmd), tap → esc
- `home-row-mods.kbd` — per-finger timing, typing layer, spotlight
- `layers.kbd` — `deflayermap` blocks for every layer; one file per layer name
- `scroll.kbd` — page up/down and top/bottom bindings

Not stowed (excluded via `kanata/.stow-local-ignore`): `README.md`, `scripts/`, and the plists.
- `com.jtroo.kanata.plist` — LaunchDaemon, installed to `/Library/LaunchDaemons/` via
  `sudo ./kanata/scripts/install-daemon.sh`
- `com.jtroo.kanata-watcher.plist` — restarts kanata when a keyboard is connected
- `com.jtroo.kanata-restarter.plist` — runs `scripts/restart-kanata.sh`

See `kanata/README.md` for setup, daemon management, and rollback.

## Karabiner

**Not used for remapping** — kanata does that. Karabiner-Elements must stay installed only
because kanata depends on its **Karabiner-DriverKit-VirtualHIDDevice** driver. The package
exists to preserve `karabiner.json` so Karabiner doesn't prompt for setup on launch.

Do not add remapping rules here. See `karabiner/README.md`.

## Zsh

`~/.zshenv` sets `ZDOTDIR=$HOME/.config/zsh`; everything else lives under `zsh/.config/zsh/`.

- `.zprofile` — login shell, PATH and exported env
- `.zshrc` — interactive shell: plugins, keybinds, tool inits, aliases
- `prompt.zsh` — prompt symbol, directory, cmd duration, vi-mode cursor
- `theme.zsh` — catppuccin colors, sourced by `prompt.zsh` and others
- `jj.zsh` — `jjw` workspace helper

Tool inits go through `_cache_init` (`.zshrc:31`), which caches a tool's init output to
`~/.cache/zsh/` so subsequent shells source a file instead of forking the command. Adding a
tool init without it costs ~10ms per shell. `rr` clears the cache and reloads.

## Atuin (shell history)

Config: `atuin/.config/atuin/config.toml`. Initialized at `.zshrc:193` with
`--disable-up-arrow`; bound to ctrl-r for both viins and vicmd.

The history database and sync key live in `~/.local/share/atuin/` and are deliberately **not**
version-controlled — `key` is a secret and `history.db` is machine state.

## Ghostty (terminal)

Config: `ghostty/.config/ghostty/config`. Includes keybind remaps for tmux compatibility
(ctrl+/, ctrl+\, ctrl+backspace send specific byte sequences).

## Tmux

Config: `tmux/.config/tmux/tmux.conf`. Prefix-less keybindings for common actions (splits,
copy mode, plugins). Helper scripts in `tmux/.config/tmux/scripts/`. Plugins are gitignored.

## Herdr (terminal multiplexer)

Config: `herdr/.config/herdr/config.toml`. Keybinds intentionally mirror `tmux.conf`.
Validate with `herdr config check`; apply with `herdr server reload-config` or prefix+r.
Plugins live in `herdr/.config/herdr/plugins/`.
