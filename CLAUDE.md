# Dotfiles

GNU Stow-managed dotfiles. Each top-level directory is a stow package that symlinks into `$HOME`.
`.stowrc` sets `--target=~/`. From the repo root: `stow <package>`.

See `README.md` for the package inventory and the `.local` override pattern.

## Claude Code

Package root is `claude/.claude/`. Stow symlinks each entry into `~/.claude/`:
`settings.json`, `settings.local.json`, `CLAUDE.md`, `agents/`, `hooks/`, `skills/`, `scripts/`,
`output-styles/`, `statusline.sh`. Everything else under `~/.claude/` (`plans/`, `projects/`,
`sessions/`, `crews/`, `history.jsonl`, caches) is machine state and stays untracked.

Work-specific scripts physically live in the package but are gitignored, so they are stowed
locally without being published. See the gitignore block for the list.

Context budget, the plan-file lifecycle contract, and the measurements behind both are in
`docs/claude-context.md`. Read it before changing `statusline.sh` thresholds, the plan hooks, or
`plan-active.sh`.

`claude/project-skills/` holds per-project skills. They are **not** stowed (see
`claude/.stow-local-ignore`) and must never land in `~/.claude/skills/`, which costs context in
every session of every project; they are symlinked into the consuming repo instead. Memory is
owned by Claude Code's built-in prompt, not a skill. Details in `docs/claude-permissions.md`.

### Settings and permissions

`settings.json` is verified against Claude Code 2.1.231, installed via Homebrew cask (trails npm by
~20 versions; `autoUpdates` has no effect). Permission rules, the deny/ask/allow layering, the
allowlist derivation, and the version-gated settings are documented in
`docs/claude-permissions.md`. **Read that file before editing `settings.json`.**

### MCP servers

`.mcp.json` at the repo root defines this repo's servers and is tracked. Playwright is defined
there but **not** in `enabledMcpjsonServers`, because loading it costs ~370 tokens of context
per session and nothing here uses it (`md-preview` drives a plain Bun server, not a browser
driver). Enable it per-session if a task genuinely needs browser automation. Everything else lives
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
  `hookSpecificOutput.additionalContext` JSON, since PostToolUse also discards plain stdout. The
  `ExitPlanMode` branch reads `tool_input.planFilePath` and checks filename, status directory,
  `repo:` frontmatter and the `## Tasks` / `## Next` sections.
- `context-budget.sh` — UserPromptSubmit, `timeout: 5`. Reminds you to reset the session past 300k
  of context. Always exits 0; it never blocks a prompt.
- `plan-rehydrate.sh` — SessionStart, `matcher: "startup|clear|compact"`, `timeout: 5`. Injects the
  active plan's resume digest. Registered as a **second** `SessionStart` entry so the vendor-managed
  `herdr-agent-state.sh` under `matcher: "*"` is left alone.

Thresholds, the 967k auto-compact derivation and the plan-lifecycle contract are in
`docs/claude-context.md`.

Only three events deliver plain exit-0 stdout to the model: `SessionStart`, `UserPromptSubmit` and
`UserPromptExpansion`. Everything else needs `hookSpecificOutput.additionalContext`, which is
supported on `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `Notification` and others, but
**not** on `PreCompact` or `PostCompact`.

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

`statusline.sh` uses one `jq` fork and bash integer comparison. Do not add per-render subprocesses.
It is not run per render: Claude Code re-runs it on a 300ms trailing debounce whenever `tokenUsage`,
the model, vim mode, effort or PR status changes, plus the optional `statusLine.refreshInterval`.

The context segment colors on **absolute token counts**, not `used_percentage`: green below 200k,
yellow at 200k, red plus an action hint at 300k. On a 1M window a percentage is useless as a warning
because auto-compact does not fire until 967k. `cap-context.sh` and `cap-crews.sh` use the same two
numbers for a crew. It reads `context_window.total_input_tokens`, which already includes cache reads
and creation; adding `total_output_tokens` to it double-counts.
Rationale and measurements in `docs/claude-context.md`.

## Captain

Phase orchestration over native agent definitions. `/captain` drives one task through eight phases —
define, survey, explore, plan, build, review, integrate, close — dispatching a crew per phase. A
crew is an ordinary Claude Code session wearing one of the 13 role definitions. Design in
`docs/design/2026-08-31-captain-to-agent-definitions.md`, which supersedes the herdr-and-jj-pool
architecture in `2026-08-28-captain-crew-orchestration.md`.

The 13 roles live in `claude/.claude/agents/`, stowed to `~/.claude/agents/`, so **any of them can
be used without the skill**: `Agent(subagent_type: "librarian")` in any session, or
`claude --agent librarian` for a whole session. The file name is what `--agent` takes; the
`role:` frontmatter key is the three-letter crew-id prefix. `SKILL.md` adds only the phase order,
the artifact convention and the gates.

Three runtimes, one definition:

| | Stdin | Survives your `/clear` |
|---|---|---|
| In-process subagent (`Agent(subagent_type: …)`) | no | no |
| Background session (`cap-crews.sh start`, i.e. `claude --bg`) | not until attached | yes |
| herdr pane running `claude attach <id>` | yes | yes |

A background session runs to completion or blocks, then exits; `blocked` in `cap-crews.sh list` is
the signal to attach and answer it. Nothing is waiting on a live process.

Three scripts, ~600 lines, replacing the eleven that came before:

- `cap-crews.sh` — `new`, `start`, `list`, `attach`. It keeps no manifest: `claude agents --json`
  already tracks every session, so `list` joins that against `$CAP_DIR` rather than holding a second
  copy of the same facts. Threshold policy lives here.
- `cap-context.sh` — the per-crew statusLine, recording tokens, cost and effort into
  `$CAP_DIR/context/<id>.json`. `claude agents --json` has no cost field, which is the only reason a
  crew needs a settings file at all.
- `cap-improve.sh` — the improvement loop, unchanged. It improves the captain rather than the
  projects it runs. Entries are append-only in `~/.claude/crews/_improve/`, each naming the file it
  wants changed; an entry that cannot name a target is refused. `cap-crews.sh list` records its own
  anomalies and prints the recurrence footer. A fact about the work goes in the crew log instead.

`tests/crews.sh` is the suite. It stubs `claude`, because the two things that needed live proof are
settled and encoded in the script: **`claude --bg` ignores `--session-id`** (so the id is read back
from what it prints) and **a background session does not inherit the launching shell's environment**
(so `CREW_ID`, `CREW_ROLE` and `CAP_DIR` travel in the generated `settings.env`).

**Runtime state is `~/.claude/crews/<slug>/` and is not version controlled.** One directory per
project holding `crews.tsv`, the briefs, the crew logs, the surveys, the questions file and the
generated per-crew settings. `_improve/` holds the improvement record and `_archive/` torn-down
projects. Claude Code owns `~/.claude/projects/`, so the captain cannot use it.

**Nothing enforces a role's boundaries.** The contract in each definition is the whole of it. The
generated per-crew settings carry env and a statusLine, not permission rules; `cap-profile.sh` and
the path denies it wrote are gone, along with the jj working-copy pool. Writers work in the copy you
are sitting in, so they are sequenced rather than concurrent. `herdr pane send-keys` and
`agent send-keys` are still deliberately **not** allowlisted, because either one is arbitrary
command execution laundered through herdr. See `docs/claude-permissions.md`.

`docs/design/YYYY-MM-DD-<name>.md` paired 1:1 with a plan of the same name is the convention the
plan phase writes to, and it is the same convention the rest of this repo already uses.

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
