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

Context budget, the workstream lifecycle contract, and the measurements behind both are in
`docs/claude-context.md`. **Read it before changing `statusline.sh` thresholds, the plan hooks, or
`ws.sh`.** Token and cost accounting — the ledger, the price table, and the three
transcript-reading traps — is in `docs/claude-metrics.md`.

`claude/project-skills/` holds per-project skills. They are **not** stowed (see
`claude/.stow-local-ignore`) and must never land in `~/.claude/skills/`, which costs context in
every session of every project; they are symlinked into the consuming repo instead. Memory is
owned by Claude Code's built-in prompt, not a skill. Details in `docs/claude-permissions.md`.

#### npx-installed skills

They land in `~/.agents/skills/` and are linked into the package as
`../../../../.agents/skills/<name>`. **Four levels, not two.** `~/.claude/skills` is itself a stow
symlink into this package, so `..` resolves through the real path; an installer that assumes a real
directory writes a two-level target that dangles, and a dangling skill fails silently — it simply
does not appear in the session's skill list.

**`scripts/skills/skills-link.sh fix` after any install**, and never repoint one by hand: the depth
is stated once, in that script. `check` is the same sweep without the writes, and it reports three
things — a link that does not resolve, a link that resolves by the wrong route, and a skill
installed but never linked. `scripts/tests/agents.sh` calls `check`, so a broken link now fails the
suite. It did not before: `code-review`, `implement`, `to-spec` and `to-tickets` sat dangling
through a 643-assertion run, and `/code-review` is named by `/planning`'s `## After the plan` table.
A real directory of the same name is repo-owned and `fix` never replaces it with a link.

They are upstream-owned, so a fix belongs upstream: an update replaces the file. A `/name` one of
them references and nobody has installed is fixed by installing that skill, which is why
`scripts/tests/agents.sh` exempts symlinked skills from the reference check and holds the repo-owned ones to
it — `/code-implement`, named three times by `writing-code-quick`, had never existed.

`tdd` and `diagnosing-bugs` replaced the local `test-driven-development` and `systematic-debugging`,
which were duplicates that contradicted each other on whether refactoring belongs inside the
red-green loop. `builder`, `adversary` and the `Skill Usage` list in the personal `CLAUDE.md` name
the npx pair, and `~/.claude/skills/tdd/tests.md` is the anti-pattern reference the two roles read
rather than invoke.

### Prose rules

Two files, one boundary. `claude/.claude/output-styles/direct.md` owns register, length, typography
and the banned-word list, and is always loaded via `outputStyle: "Direct"`.
`claude/.claude/skills/writing-design-docs/plain-language.md` owns the sentence-level limits and is
read on demand, reachable only through `/writing-design-docs`. **It cannot gain a pointer from
`writing-for-agents`**, which is upstream-owned and whose file an npx update replaces, so this
section is the pointer instead: read `plain-language.md` before writing prose into a skill, a
`CLAUDE.md`, or a doc under `docs/`. The personal
`claude/.claude/CLAUDE.md` keeps only the push-back rule; its banned-word list moved into
`direct.md`, because two always-loaded files carrying one list spent context to say a thing twice.

**The rules bind chat and anything written from now on. Existing files are frozen and are not
rewritten to conform.** So this file's 39 em dashes, `docs/captain.md`'s 49 and the 40 uses of
"real" across the docs are exempt rather than debt. No file can show the difference between an
exempt line and a breach, which is why the freeze is recorded here.

`unslop`, a hand-vendored copy of `pstack/skills/unslop/SKILL.md` from `cursor/plugins`, was
removed on 2026-09-03 the day it landed. Twenty-two of its thirty-one items duplicated the two
files above, item 8 near-verbatim against `direct.md`. Item 26 bans `harness`, `surface` and
`scaffolding`, which the docs here use as settled vocabulary; item 13 also bans parentheses; and
its "Adding soul" section asks for "let some mess in", against `direct.md`'s structure rules. By
`writing-for-agents:74` it is also built the wrong way round, as thirty-one prohibitions rather
than positive targets. The eight items worth keeping are now rules 18 to 25 of `plain-language.md`,
with the colon and adverb rules also in `direct.md` since both apply to chat. Re-vendoring it
restores the duplication, so do not.

### Agent definitions

`claude/.claude/agents/*.md`, stowed to `~/.claude/agents/`. Verified against 2.1.231 by reading
the binary and by live dispatch.

Definitions are merged into a map keyed by the frontmatter `name:`, in this order, last write
winning: **built-in → plugin → userSettings (`~/.claude/agents/`) → projectSettings
(`.claude/agents/`) → flagSettings → policySettings.** So a definition named after one of Claude
Code's own agents (`Explore`, `Plan`, `general-purpose`, `claude`, `statusline-setup`) replaces it
wholesale — prompt, tools and model — and the agent list shows one entry, not two.

`Explore.md` is the one override here, and it exists for the `model: haiku` pin: a built-in Explore
inherits the session model, so on `opus[1m]` it greps excerpts at opus prices. **It also owns the
report contract** — `path:line` citations, a 600-word budget, bounded reads — so a dispatch prompt
does not restate any of that. Mechanics and the measurements behind the contract are in
`docs/captain.md`.

### Planning

**Planning has one entry point: `/planning`.** It is the process, and it dispatches the three roles
that do the work as background crews — `Plan` stage one for the Overview tier of the design doc,
`Plan` stage two for the choice and the two documents, `adversary` to attack them, `checker` to run what the adversary could not settle by reading, then `Plan` to amend.
The default round cap is one attack-and-amend; `Plan`'s own contract allows three before what is
unresolved goes to the user, and that is a ceiling rather than a target. A brief may ask for a
second round; the skill already allows it without changing.

**`Plan` stage one opens with `grilling` unless its brief says `discovery: none`.** Nothing emits
that line any more — `cap-phases.sh modes` did, and it went with `/captain` — so the brief's author
writes it, and a run that does not write it gets the dialogue. That is the intended default rather
than an oversight: the skill's own guidance already rules it out for a one-file change, an obvious
bug or a decision with no trade-off, so anything reaching it is work whose shape is worth agreeing
first.

Format versus process. `/planning` owns the process and adds no naming, location or section rule of
its own. `/writing-plans`, `/writing-design-docs` and `/workstreams` own the format and the lifecycle, and `Plan`
invokes them itself — the skill never does. Those three still auto-invoke on their own words, so a
prompt about writing a plan can pull one in beside `/planning`; the tie-break, written into
`/planning`, is that it owns the process and you do not reach the format skills directly. Making them
`disable-model-invocation: true` was the alternative and was rejected: writing a plan by hand would
stop pulling the format rules in.

Background crews rather than in-process subagents, because the loop is long enough that the session
hits a context boundary before it ends, and a `--bg` crew survives a `/clear`. That needs a
`$CAP_DIR`, so the skill makes its own with `cap-crews.sh new` unless one is already set, in which
case it checks each gate against the files already there and enters part-way rather than
redispatching.

**`/planning` also owns what follows the plan.** Its `## After the plan` table names build, review,
security, verify, integrate and close, and says to write each one the task needs in as a step in
`PLAN.md`. That is deliberate: `/captain`'s manifest was the only thing recording that a review had
been *skipped* rather than forgotten, and `PLAN.md` plus `PROGRESS.md`'s `## Tasks` is where that
record lives now.

**A SKILL.md body gets positional-argument expansion at load.** A dollar sign followed by a single
digit is replaced by the word at that position in whatever arguments the skill was invoked with —
`/planning`'s cost table read `confirming.90` instead of `$3.90` the first time it was loaded with
arguments. Named variables such as `$CAP_DIR` are untouched. So money in a skill body is written
`USD 3.90`, and `scripts/tests/agents.sh` fails any skill or agent definition carrying the sequence.

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
- `scripts/metrics/metrics-track.sh` — one script on four events. `Stop` (`asyncRewake`) reduces the
  transcript incrementally into a sidecar; `SubagentStop` turns `agent_transcript_path` into a
  ledger row; `SessionEnd` finalises, and fires on `/clear` and `/resume` rather than only on exit;
  a third `SessionStart` entry sweeps sidecars whose session is gone. See `docs/claude-metrics.md`.

`scripts/metrics/` also holds `metrics-note.sh` (record a cause the transcript cannot see),
`metrics-baseline.sh` (the exact token cost of a file, by differential probe — costs money,
gated behind `--yes`, never call it from a hook) and `thresholds.json` (what makes a number
bad, as data so a diff can review a change to one).

### Self-improvement

`/self-improve` audits the setup through four lenses — evidence from the ledger, conformance
against the installed Claude Code version, fit of each definition to its job, and structure the
repo contradicts about itself. It ranks findings and stops; picking is yours, and what you pick
goes to a workstream and `/planning`.

`scripts/improve/improve-record.sh` is the record behind it, append-only at
`~/.claude/improve/record.jsonl`. **An entry names the file it wants changed or it is refused** —
that filter is the difference between a record and a write-only lessons log. `kind` is open and
never checked against a list, because a loop that cannot say "this should not exist" only accretes.
Three entries against one target is a design defect; `cap-crews.sh list` prints that footer.

It was `captain/cap-improve.sh` until 2026-09-03 and never once written to, because a recorder only
a captain run can reach records only what a captain run notices. `docs/claude-improve.md` has the
schema, the two design constraints and why the four lenses are the four. **Read it before changing
a lens, the record's fields, or the recurrence threshold.**

**A retrospective or a change to a skill, an agent definition or a steering file opens with
`/metrics`.** It reads the ledger and the friction stream and reports what breached a threshold,
so those changes are argued from evidence rather than from memory. `/retro` owns the taxonomy
and `/metrics` supplies the numbers; you do not reach `metrics-report.sh` directly for that
purpose. The skill's description is scoped to trigger on retrospective and skill-authoring
language and deliberately not on "what did this cost", which is `metrics-report.sh spend`.

**A hook whose `command` path is wrong fails silently** — Claude Code does not surface it, so the
only symptom is that whatever it recorded stops arriving. `scripts/tests/settings.sh` asserts every
`command` in `settings.json` resolves to an executable file both in the package and at its stowed
path, and that all four events still name `metrics-track.sh`. Run it after touching `settings.json`
or renaming anything a hook calls.

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
reading only says the session has run a while. `metrics-report.sh efficiency` answers it after the
fact. See `docs/claude-metrics.md`.

The cost sidecar it writes goes through `metrics_cost_stamp` in `scripts/metrics/metrics-cost.sh`,
shared with `cap-context.sh`. That writer is a separate file from `metrics-lib.sh` because sourcing
the library forks at source time and its own writer forks `mkdir`; both callers run on a render.

**Crew spend rides in a bracket after the cost**, `[󱃾 3 | 412k | $44.00*]`, whenever the session's
repo has a `.current` pointer beside its workstreams. A statusline spawned by Claude Code never
sees a dispatching session's `$CAP_DIR`, so it resolves the repo key the way `ws.sh` does, by walking up from
its own cwd for a `.jj` or `.git` marker with builtins only. Two implementations of one rule, and
`tests/crews.sh` asserts they agree. Still one fork: the
figures are summed from `$CAP_DIR/context/<crew>.peak`, bare integers `cap-context.sh` already
writes, with a glob and a `read` per file. It closes a real gap — the `stripe-idempotency-key` run
held 1,284k of crew context against an 84k dispatching session, none of it in view. Peaks rather than
live levels, so a finished run still reads as expensive, and coloured on the worst single crew, since
300k is an instruction to re-dispatch *that* crew. Blocked state and live crew cost are deliberately
absent: both need a fork, and a stamped copy of either goes quiet exactly when it matters. The `*`
says the cost is as of the last `cap-crews.sh list`.

The context segment colors on **absolute token counts**: green below 200k, yellow at 200k, red plus
an action hint at 300k. **The percentage it prints is measured against that 300k budget, not against
the context window** — `context_window.used_percentage` is not read by either statusline, because on
a 1M window it makes the reset point read as 30% when auto-compact does not fire until 967k. So red
and 100% arrive together, and past the budget the figure is left uncapped: 420k renders 140%. It is a
whole percent by bash integer arithmetic, which adds no fork. `cap-context.sh` and
`cap-crews.sh` use the same two numbers for a crew, so a crew pane reads 100% at the point
`cap-crews.sh` says to checkpoint it. Both read `context_window.total_input_tokens`, which already
includes cache reads and creation; adding `total_output_tokens` to it double-counts.
Rationale and measurements in `docs/claude-context.md`.

## Crews

Role dispatch over native agent definitions. A crew is an ordinary Claude Code session wearing one
of the six role definitions in `claude/.claude/agents/`, started by
`claude/.claude/scripts/captain/cap-crews.sh`. `$CAP_DIR` is the workstream `ws.sh` returns,
untracked under `~/.claude/work/<repo>/`.

**`/captain` was retired on 2026-09-03.** It was a step catalogue above the plan loop, and one run
of it spent USD 75 and 3h22m for zero lines of code because nothing in the loop could see the size
of the change. `/planning` is the entry point; its `## After the plan` table names what follows a
plan. `skills/captain/`, `cap-phases.sh`, `cap-signoff.sh` and `hooks/captain-signoff.sh` are gone.
`cap-crews.sh` and `cap-context.sh` stay: `/planning` dispatches with the first and `statusline.sh`
reads what the second writes. ADR 0003 records the decision.

**A session that dispatches crews does not read repo files.** No `Read`, `Grep`, `Glob`, `Edit` or
`jj diff` on anything in the repo, including while integrating, where the step is yours but the
reading is not. Reading is a dispatch. This rule stays in steering because it is the one a session
must not have to look up.

**Nothing enforces a role's boundaries.** Every contract is prose in a definition, so a boundary
crossed is crossed.

**Never run `jj resolve`.** It opens an editor, the editor here is configured to fail, and a session
stuck in one looks alive from outside. Resolve a conflict by editing the markers jj wrote into the
files, then let the next command snapshot it. A fact about this repo rather than about a role.

Rationale, measurements and the script inventory are in `docs/captain.md`, which kept its filename.
**Read it before changing a role definition, a `cap-*.sh` script, or the crew statusline.**

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
