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

Two things the override cannot keep. The frontmatter schema has no `omitClaudeMd`, so unlike the
built-in it does receive both CLAUDE.md files on every dispatch. And the prompt is a copy, so a
newer Claude Code improving its own Explore prompt will not reach ours. `agentType === "Explore"`
is special-cased by name regardless of source, so git status is still stripped from its context.

Supported frontmatter keys, from the schema: `name`, `description`, `tools`, `disallowedTools`,
`model`, `effort`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`,
`memory`, `background`, `isolation`, `observer`. `effort:` takes `low|medium|high|xhigh|max` and is
carried on the definition, so the 13 crew roles do not need `--effort` at dispatch — the design doc
records it as unverified documentation, which was true then and is not now. Unknown keys are
tolerated, which is what lets `role:`, `phase:` and `log_sections:` ride along.

### Planning

**Planning has one entry point: `/planning`.** It is the process, and it dispatches the four roles
that do the work as background crews — `Plan` stage one for the problem statement, `librarian` in
parallel for the surveys, `Plan` stage two for the choice and the two documents, `adversary` to
attack them, `checker` to run what the adversary could not settle by reading, then `Plan` to amend.
The default round cap is one attack-and-amend; `Plan`'s own contract allows three before what is
unresolved goes to the user, and that is a ceiling rather than a target.

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
`$CAP_DIR` is already set and `/captain`'s define and survey phases are steps the skill finds already
done — its gates are readable off the files, so it enters part-way without redispatching. `/captain`'s
plan phase is one table row naming the skill; it no longer describes the sequence.

**A SKILL.md body gets positional-argument expansion at load.** A dollar sign followed by a single
digit is replaced by the word at that position in whatever arguments the skill was invoked with —
`/planning`'s cost table read `confirming.90` instead of `$3.90` the first time it was loaded with
arguments. Named variables such as `$CAP_DIR` are untouched. So money in a skill body is written
`USD 3.90`, and `tests/agents.sh` fails any skill or agent definition carrying the sequence.

The cost section is measured, not estimated: `pla-104` reached a first reviewed draft for about $110,
and the numbers are per crew in the skill. The lesson in them is that **model tier is the smaller
lever**. Sonnet ran $0.036–$0.061 per 1k of context against opus at $0.074–$0.094, about 2x, while
context read varied 4.5x across crews — three sonnet `librarian` crews cost $27.88 together, more
than half the opus planner. A tight read-first list saves more than a cheaper model does.

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

The context segment colors on **absolute token counts**, not `used_percentage`: green below 200k,
yellow at 200k, red plus an action hint at 300k. On a 1M window a percentage is useless as a warning
because auto-compact does not fire until 967k. `cap-context.sh` and `cap-crews.sh` use the same two
numbers for a crew. It reads `context_window.total_input_tokens`, which already includes cache reads
and creation; adding `total_output_tokens` to it double-counts.
Rationale and measurements in `docs/claude-context.md`.

## Captain

Step orchestration over native agent definitions. `/captain` drives one task through the steps it
needs, dispatching a crew per step. A crew is an ordinary Claude Code session wearing one of the 6
role definitions. Design in `docs/design/2026-08-31-captain-to-agent-definitions.md`, which
supersedes the herdr-and-jj-pool architecture in `2026-08-28-captain-crew-orchestration.md`; the
per-task step selection is in `2026-08-31-captain-adaptive-phases.md`.

**No step is mandatory.** The catalogue is define, survey, plan, build, review, security, verify,
integrate, close, plus `tdd` as a mode on build — ten rows, of which the last two steps are the
captain's own rather than a crew's. The seven-phase sequence that came before ran everything on
every task, so declining to plan a one-file change had no representation other than not doing it and
saying nothing. Three of those rows are the old single `review` phase split apart, because reading a
change, security-reading it and running its suite are independently worth skipping.

The set is chosen once at the start — the captain proposes from the task and asks once, rather than
prompting per step — and lives in `$CAP_DIR/phases.tsv`, so it survives a `/clear` and
`cap-crews.sh list` can print it. Every row carries a state (`included`, `skipped`, `done`) and a
reason. There is no `active` state: `cap-phases.sh next` derives it as the first row that is neither
done nor skipped, because a state advanced by hand drifts out of step with the artifacts. A skip is
revisable with `cap-phases.sh add <step> --reason "scope grew"`, and that reason column is the record
of why the original judgement was wrong.

Nothing enforces the manifest either. It records what was decided; doing a step marked skipped is not
an error, it is just undocumented.

**Every included step stops for a sign-off, and the sign-off is checked against a transcript.**
`cap-phases.sh done` refuses unless the gate artifact exists, `--signoff "<their words>"` is given,
and `cap-signoff.sh` finds a human. Two routes count: an `AskUserQuestion` in the captain's own
transcript, or a second human turn in a crew's. The second is the stronger one and the one to design
for — a never-attached `--bg` crew's transcript holds exactly one string-content `user` record, its
launch prompt, and everything else with `type: "user"` is a `tool_result`. Measured across six real
transcripts: three background crews at 1, 1, 1 and three interactive sessions at 7, 10, 7. The
captain cannot write into another session's file, so a second turn is proof a person was there.

That route exists because of how the captain is now constrained: it may not read repo files, so it
relaying a summary of a design doc is worse than the requester reading the doc in the crew's tab.
Crews get `cap-phases.sh signoff-brief <step>` in their brief, which tells them to write the artifact
and then ask rather than exit — they show as `blocked`, the channel `cap-crews.sh list` and `attach`
already handle. `cap-phases.sh reject` sends a step back with a reason and a count, leaving it
`included` and the tab open.

Every signal must be newer than `max(step.since, newest artifact mtime)`, since approval cannot
predate the work. `since` is the manifest's fifth column, written on every state change, which is
also what gives `build`, `integrate` and `close` — the three steps with no artifact under `$CAP_DIR`
— something to compare against.

**Sign-off is also when a tab is torn down.** Nothing closed one before: `open_tab` printed the tab
id and discarded it, so `crews.tsv` could not say which tab belonged to which crew, and two real runs
left six crew tabs sitting idle across two workspaces. `crews.tsv` is four columns now — crew id,
harness id, tab, step — and `cap-phases.sh done` calls `cap-crews.sh close --step` once the step is
agreed. `cap-crews.sh down [--archive]` ends the project; archiving is opt-in because a resumed run
needs the directory where `new` put it, and it is what finally makes `_archive/` real rather than
aspirational.

**`close` never touches a `blocked` crew.** That one is waiting for you, and closing it discards both
the question and the only session that can answer it. Nor does it close before sign-off: after the
contract change the captain may not read repo files, so the crew's tab is the review surface, and
route B approval happens inside it. Outside herdr, or on a row from before the column change, there
is nothing to close and it exits clean.

`hooks/captain-signoff.sh` is **the first `PreToolUse` hook in this repo**. It denies `done` when
unverified and denies writing `phases.tsv` any other way, because `sed -i` on a file the captain may
write is the obvious way round. It fails open on anything unexpected: this guards a process, it is
not a security boundary. Its `timeout` must exceed a transcript read — a cancelled hook has its
output discarded, which here would silently allow the thing it exists to deny.

Design in `docs/design/2026-08-31-captain-step-signoff.md`.

**The captain has a contract now, `## What the captain does not do`, and it is absolute.** It was the
only participant without one — all six roles end with a `Never:` list and all six carry the same
"Delegate reading to subagents" sentence, while `SKILL.md` had neither, which is how a run ended up
with the captain reading the code and briefing nobody. No `Read`, `Grep` or `Glob` on a repo file, no
`Edit`, no `jj diff`, including at `integrate` where the reading is a `checker` dispatch even though
the step is the captain's. `tests/agents.sh` asserts the shared sentence is byte-identical across all
seven files, so rewording one leaves the others failing rather than silently diverging.

Selection was rewritten with it. The first version's heuristic table needed code knowledge for seven
of its ten rows and made having read the code the reason to skip the crew that would have; it is
deleted rather than patched. The captain now restates the task, asks four questions none of which is
answerable by reading, walks the catalogue out loud with a reason per row, and writes the manifest.
"Not sure" includes `survey` and puts the question in the `librarian` brief, so uncertainty about the
code routes to a crew instead of into the captain's context. None of it is enforced: `/captain` is a
skill, so it has no `tools:` line and its session keeps every tool it had.

**`tdd` is the one mode, and `builder` is the one definition it changes.** `builder.md` kept
test-first as an absolute — write the test, watch it fail, commit it alone — which made it unusable
on a repo with no suite or on a config change. It now has exactly one escape, the literal line
`tests: none` in its brief, emitted by `cap-phases.sh modes builder` when the `tdd` row is skipped.
A literal token rather than a prose condition is what makes it assertable in `tests/agents.sh`, and
`builder`'s Never list forbids it granting itself the escape. That is a prose rule guarding a prose
rule, which is the same trade the thirteen-to-six merge already made twice.

The 6 roles live in `claude/.claude/agents/`, stowed to `~/.claude/agents/`, so **any of them can
be used without the skill**: `Agent(subagent_type: "librarian")` in any session, or
`claude --agent librarian` for a whole session. The file name is what `--agent` takes, and a crew id
is that name plus the task slug — `adversary-plan-x`, not `arc-plan-x`. The `role:` frontmatter key
is what is left of the old three-letter prefix: a shorter thing to type at `cap-crews.sh start`, and
the marker distinguishing a crew role from `Explore.md`, which has no `role:`. `SKILL.md` adds only
the phase order, the artifact convention and the gates.

Thirteen became six, in three passes, and the direction throughout was that a role must earn a file.

Merged because two definitions described one job: `verifier` into `checker` (both recorded verbatim
command output and judged nothing, differing only in whether the input was an assumption list or a
build plus suite); `product-manager` into `Plan` as stage one; `architecture-reviewer` and
`code-reviewer` into `adversary`, which attacks any artifact's claims — every claim checked against
its source as **holds**, **refuted** or **unsupported**, then the reasoning attacked; `test-writer`
and `code-writer` into `builder`, which writes the test, watches it fail and commits it alone before
implementing.

Cut because the job was gone or belonged to the captain: `option-generator`, and the explore phase
with it — never run in the one real project, whose Plan produced a 1,626-line plan with no
`options.md` in breach of its own contract, so the option discipline moved inside `Plan` as a
required `## Rejected approaches`. `integrator`, whose lens was combining changes across the jj
working-copy pool that the previous changeset deleted; sequenced writers in one shared copy leave a
linear stack, so integration is a captain step and the one rule worth keeping — never `jj resolve`,
it opens an editor configured to fail — moved to `SKILL.md`. `scribe`, because ticking `## Tasks` is
already a captain duty and its doc-against-code check is the adversary's survey case.

Renamed: `explorer` to `option-generator` before it was cut, because it sat in the same listing as
`Explore` doing the opposite job; `prober` to `checker`. Not `verifier` — that names an outcome for a
role whose defining rules are that `inconclusive` is a result and that it must never report a pass it
did not watch happen.

Two of these merges traded a structural guarantee for a prose rule, and an `adversary` run on the
design doc said so. Two definitions with different `phase:` keys could not be pointed at the wrong
artifact; one definition with a "one dispatch, one artifact" sentence can be. Same for the
test-before-code boundary. Accepted twice, for the same reason: nothing enforced a role's boundaries
anyway.

Every description lost its "Dispatch explicitly" clause, reversing plan task A4: the roles are meant
to be auto-selected. That was riskiest while `integrator` existed, since it rewrote history in the
copy everyone was sitting in; cutting it removed the worst case, and no definition rewrites history
now. `builder` is what remains to watch — auto-selected without a plan step to build, it has nothing
but its own contract telling it to stop.

Three runtimes, one definition:

| | Stdin | Survives your `/clear` |
|---|---|---|
| In-process subagent (`Agent(subagent_type: …)`) | no | no |
| Background session (`cap-crews.sh start`, i.e. `claude --bg`) | not until attached | yes |
| herdr pane running `claude attach <id>` | yes | yes |

A background session runs to completion or blocks, then exits; `blocked` in `cap-crews.sh list` is
the signal to attach and answer it. Nothing is waiting on a live process.

Five scripts, ~1000 lines, replacing the eleven that came before:

- `cap-crews.sh` — `new`, `start`, `list`, `watch`, `attach`. It keeps no crew manifest:
  `claude agents --json` already tracks every session, so `list` joins that against `$CAP_DIR` rather
  than holding a second copy of the same facts. Threshold policy lives here. `list` also prints one
  `PHASES:` line from `phases.tsv` — one awk over one file, so resuming after a `/clear` is one
  command, not two.

  **It opens a herdr tab per crew.** `claude --bg` is detached and has no pane, and `attach` used to
  only print `claude attach <id>` for you to paste, so a dispatched crew was unwatchable without
  manual work. `start` now runs `herdr tab create --cwd "$PWD" --label <crew-id> --no-focus`, reads
  `.result.root_pane.pane_id`, and `herdr pane run <pane> "claude attach <short-id>"`. `--no-focus`
  always, so a fanned-out `librarian` cannot steal focus five times; `--no-watch` opts out.
  `watch [<crew-id>...]` does the same after the fact, and bare `watch` targets every crew the
  harness reports `blocked`.

  **This needs no new permission, and that is the design rather than a loophole.** The herdr calls
  are inside the script, and `settings.json` already allowlists `Bash(bash …/captain/cap-*.sh*)`.
  `docs/claude-permissions.md` says why that is the right boundary: a script validates its arguments
  instead of interpolating caller input into a `herdr` call. `pane send-keys` and `agent send-keys`
  stay denied. Anything that fails — no `HERDR_ENV`, a herdr call erroring — falls back to printing
  the attach line and exits 0, because a monitoring convenience must never fail a dispatch.

  The pane id key was probed live: the herdr skill documents `.result.pane.pane_id`, which is
  `pane split`'s shape. `tab create` returns it under `root_pane`.
- `cap-signoff.sh` — `verify <step>`, answering "was a human actually here" from transcripts rather
  than from a claim. Exit 1 is an honest no; exit 2 is its own error, which the hook distinguishes so
  a broken verifier does not read as a refusal.
- `cap-phases.sh` — the step manifest: `init`, `list`, `skip`, `add`, `done`, `reject`, `next`,
  `modes`, `signoff-brief`, `catalogue`. The catalogue is a literal array at the top of the script, and `tests/agents.sh`
  checks every row `SKILL.md` names is a row the script knows, so the skill cannot document a step no
  command can mark done. It refuses the incoherent — an unknown id, skipping a `done` step, finishing
  a `skipped` one — and warns rather than refuses when `tdd` is included with `build` skipped.
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
project holding `crews.tsv`, `phases.tsv`, the briefs, the crew logs, the surveys, the questions file
and the generated per-crew settings. `_improve/` holds the improvement record and `_archive/` torn-down
projects. Claude Code owns `~/.claude/projects/`, so the captain cannot use it.

**Nothing enforces a role's boundaries.** The contract in each definition is the whole of it. The
generated per-crew settings carry env and a statusLine, not permission rules; `cap-profile.sh` and
the path denies it wrote are gone, along with the jj working-copy pool. Writers work in the copy you
are sitting in, so they are sequenced rather than concurrent. `herdr pane send-keys` and
`agent send-keys` are still deliberately **not** allowlisted, because either one is arbitrary
command execution laundered through herdr. See `docs/claude-permissions.md`.

**Cost is no longer read from `$CAP_DIR/context/<crew>.json`.** That file is overwritten on every
render, and `SKILL.md` tells you to re-dispatch a stalled crew under the same id past 300k, so each
re-dispatch silently discarded the previous session's spend — the recorded `pla-104` total is a
floor, not a measurement. `cap-crews.sh list` now sums the usage ledger by crew. The per-crew JSON
still carries `tokens`, which is a level and belongs to the running session, plus a `peak_ctx`
running max, since context drops at a compaction. Its `usage` field is gone: it held one message's
counts under a name implying cumulative totals. See `docs/claude-usage.md`.

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
