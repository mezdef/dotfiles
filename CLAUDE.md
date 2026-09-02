# Dotfiles

GNU Stow-managed dotfiles. Each top-level directory is a stow package that symlinks into `$HOME`.
`.stowrc` sets `--target=~/`. From the repo root: `stow <package>`.

See `README.md` for the package inventory and the `.local` override pattern.

Repo vocabulary lives in `CONTEXT.md` at the root, and a decision that is hard to reverse in
`docs/adr/NNNN-slug.md`. `domain-modeling` owns both formats and creates each on the first entry,
so an absent file means nothing has needed one yet.

## Claude Code

Package root is `claude/.claude/`. Stow symlinks each entry into `~/.claude/`:
`settings.json`, `settings.local.json`, `CLAUDE.md`, `agents/`, `hooks/`, `skills/`, `scripts/`,
`output-styles/`, `statusline.sh`. Everything else under `~/.claude/` (`plans/`, `projects/`,
`sessions/`, `crews/`, `history.jsonl`, caches) is machine state and stays untracked.

Work-specific scripts physically live in the package but are gitignored, so they are stowed
locally without being published. See the gitignore block for the list.

Context budget, the plan-file lifecycle contract, and the measurements behind both are in
`docs/claude-context.md`. **Read it before changing `statusline.sh` thresholds, the plan hooks, or
`plan-active.sh`.** Token and cost accounting — the ledger, the price table, and the three
transcript-reading traps — is in `docs/claude-usage.md`.

`claude/project-skills/` holds per-project skills. They are **not** stowed (see
`claude/.stow-local-ignore`) and must never land in `~/.claude/skills/`, which costs context in
every session of every project; they are symlinked into the consuming repo instead. Memory is
owned by Claude Code's built-in prompt, not a skill. Details in `docs/claude-permissions.md`.

### Agent definitions

`claude/.claude/agents/*.md`, stowed to `~/.claude/agents/`. Verified against 2.1.231 by reading
the binary and by live dispatch.

Definitions are merged into a map keyed by the frontmatter `name:`, in this order, last write
winning: **built-in → plugin → userSettings (`~/.claude/agents/`) → projectSettings
(`.claude/agents/`) → flagSettings → policySettings.** So a definition named after one of Claude
Code's own agents (`Explore`, `Plan`, `general-purpose`, `claude`, `statusline-setup`) replaces it
wholesale — prompt, tools and model — and the agent list shows one entry, not two.

`Explore.md` is the one override here. A built-in Explore declares `model: "inherit"` and the only
adjustment is an upper cap: on a model above opus it drops to opus, otherwise it inherits. On
`opus[1m]` that means excerpt grepping at opus prices. A non-built-in definition has its declared
`model:` honoured verbatim, so ours pins `haiku`. Confirmed by `modelUsage` in `stream-json`:
`claude-haiku-4-5` for the subagent, `claude-opus-5[1m]` for the session.
`CLAUDE_CODE_DISABLE_EXPLORE_INHERIT_CAP` only removes the cap; it cannot lower the model.

### Planning

**Planning has one entry point: `/planning`.** It is the process, and it dispatches the three roles
that do the work as background crews — `Plan` stage one for the Overview tier of the design doc,
`Plan` stage two for the choice and the two documents, `adversary` to attack them, `checker` to run what the adversary could not settle by reading, then `Plan` to amend.
The default round cap is one attack-and-amend; `Plan`'s own contract allows three before what is
unresolved goes to the user, and that is a ceiling rather than a target. A `/captain` run on the
`epic` tier asks for two rounds in the brief, which the skill already allows without changing.

**`Plan` stage one opens with `grilling` unless its brief says `discovery: none`.** Only
`/captain` emits that line, and only on the `fix` tier, so a standalone `/planning` run always gets
the dialogue. That is the intended default rather than an oversight — the skill's own guidance
already rules it out for a one-file change, an obvious bug or a decision with no trade-off, so
anything reaching it is work whose shape is worth agreeing first.

Format versus process. `/planning` owns the process and adds no naming, location or section rule of
its own. `/writing-plans`, `/writing-design-docs` and `/managing-plans` own the format, and `Plan`
invokes them itself — the skill never does. Those three still auto-invoke on their own words, so a
prompt about writing a plan can pull one in beside `/planning`; the tie-break, written into
`/planning`, is that it owns the process and you do not reach the format skills directly. Making them
`disable-model-invocation: true` was the alternative and was rejected: writing a plan by hand would
stop pulling the format rules in.

Background crews rather than in-process subagents, because the loop is long enough that a plan-phase
session hits a context boundary before it ends, and a `--bg` crew survives a `/clear`. That needs a
`$CAP_DIR`, so outside a `/captain` run the skill makes its own with `cap-crews.sh new`. Inside one,
`$CAP_DIR` is already set and `/captain`'s define step is one the skill finds already done — its
gate is readable off the files, so it enters part-way without redispatching. `/captain`'s
plan phase is one table row naming the skill; it no longer describes the sequence.

**A SKILL.md body gets positional-argument expansion at load.** A dollar sign followed by a single
digit is replaced by the word at that position in whatever arguments the skill was invoked with —
`/planning`'s cost table read `confirming.90` instead of `$3.90` the first time it was loaded with
arguments. Named variables such as `$CAP_DIR` are untouched. So money in a skill body is written
`USD 3.90`, and `tests/agents.sh` fails any skill or agent definition carrying the sequence.

Cost, and what the two expensive crews were, is in `docs/captain.md`.

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
- `scripts/usage/usage-track.sh` — one script on four events. `Stop` (`asyncRewake`) reduces the
  transcript incrementally into a sidecar; `SubagentStop` turns `agent_transcript_path` into a
  ledger row; `SessionEnd` finalises, and fires on `/clear` and `/resume` rather than only on exit;
  a third `SessionStart` entry sweeps sidecars whose session is gone. See `docs/claude-usage.md`.

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

It renders context and session cost. Cost is `cost.total_cost_usd`, which already includes
in-process subagent spend and which the statusline previously discarded. A cache-hit segment was
tried and removed: measured across 632 sessions the ratio tracks session length rather than
anything you control, from a median 61% under 100k of context read to 97% over 10M, so a high
reading only says the session has run a while. `usage-report.sh efficiency` answers it after the
fact. See `docs/claude-usage.md`.

**Crew spend rides in a bracket after the cost**, `[󱃾 3 | 412k | $44.00*]`, whenever the session's
directory has a pointer under `~/.claude/crews/_active/`. `cap-crews.sh new` writes that pointer,
because a statusline spawned by Claude Code never sees the captain's `$CAP_DIR`. Still one fork: the
figures are summed from `$CAP_DIR/context/<crew>.peak`, bare integers `cap-context.sh` already
writes, with a glob and a `read` per file. It closes a real gap — the `stripe-idempotency-key` run
held 1,284k of crew context against an 84k captain session, none of it in view. Peaks rather than
live levels, so a finished run still reads as expensive, and coloured on the worst single crew, since
300k is an instruction to re-dispatch *that* crew. Blocked state and live crew cost are deliberately
absent: both need a fork, and a stamped copy of either goes quiet exactly when it matters. The `*`
says the cost is as of the last `cap-crews.sh list`.

The context segment colors on **absolute token counts**, not `used_percentage`: green below 200k,
yellow at 200k, red plus an action hint at 300k. On a 1M window a percentage is useless as a warning
because auto-compact does not fire until 967k. `cap-context.sh` and `cap-crews.sh` use the same two
numbers for a crew. It reads `context_window.total_input_tokens`, which already includes cache reads
and creation; adding `total_output_tokens` to it double-counts.
Rationale and measurements in `docs/claude-context.md`.

## Captain

Step orchestration over native agent definitions. `/captain` drives one task through the steps it
needs, dispatching a crew per step — a crew being an ordinary Claude Code session wearing one of the
five role definitions in `claude/.claude/agents/`. The skill is
`claude/.claude/skills/captain/SKILL.md`, the scripts are `claude/.claude/scripts/captain/cap-*.sh`,
and runtime state is untracked under `~/.claude/crews/<slug>/`.

**The captain does not read repo files.** No `Read`, `Grep`, `Glob`, `Edit` or `jj diff` on anything
in the repo, including at `integrate`, where the step is the captain's but the reading is not.
Reading is a crew dispatch. This rule stays in steering because it is the one a session must not
have to look up.

**Nothing enforces a role's boundaries.** Every contract is prose in a definition, so a boundary
crossed is crossed.

Rationale, measurements and the script inventory are in `docs/captain.md`. **Read it before changing
a step gate, a sign-off route, a role definition, a `cap-*.sh` script, or the crew statusline.**

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
