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

The personal `claude/.claude/CLAUDE.md` records what `direct.md` owns and is loaded in every repo,
so it is not restated here. What only this repo can say:
`claude/.claude/skills/writing-design-docs/plain-language.md` owns the sentence-level limits and is
read on demand through `/writing-design-docs`. **It cannot gain a pointer from `writing-for-agents`**,
which is upstream-owned and whose file an npx update replaces, so this section is the pointer
instead: read `plain-language.md` before writing prose into a skill, a `CLAUDE.md`, or a doc under
`docs/`.

**The rules bind chat and anything written from now on. Existing files are frozen and are not
rewritten to conform.** No file can show the difference between an exempt line and a breach, which
is why the freeze is recorded here.

### Agent definitions

`claude/.claude/agents/*.md`, stowed to `~/.claude/agents/`.

**A definition named after one of Claude Code's own agents replaces it wholesale** — prompt, tools
and model — because definitions merge into a map keyed by the frontmatter `name:`. `Explore.md` is
the one override here and it exists for the `model: haiku` pin; it also owns the report contract, so
a dispatch prompt does not restate `path:line` citations, the word budget or bounded reads.

The merge order, the mechanics and the measurements behind the contract are in `docs/captain.md`.
**Read it before changing a definition.**

### Planning

**Planning has one entry point: `/planning`.**

Format versus process. `/planning` owns the process and adds no naming, location or section rule of
its own; `/writing-plans`, `/writing-design-docs` and `/workstreams` own the format and the
lifecycle, and `Plan` invokes them itself. You do not reach them directly.

**`Plan` stage one opens with `grilling` unless its brief says `discovery: none`.** Nothing emits
that line any more, so the brief's author writes it.

**`/planning` also owns what follows the plan.** Its `## After the plan` table names build, review,
security, verify, integrate and close, and each one the task needs is written in as a step in
`PLAN.md`. Every row is a judgement call, review included. A row left out is a decision, and
`PLAN.md` plus `PROGRESS.md`'s `## Tasks` is where that record lives.

**The `adversary` and `checker` round inside `/planning` is offered, not run.** The loop ends when
`Plan` reports the draft. Both roles stay installed and reachable by name. What changed on
2026-09-23 is that dispatching one is the caller's decision. ADR 0005 has the ledger figures.

**`security-reviewer` is retired, same day.** Its one mandatory step ran `/security-review`, a skill
that has never existed on this machine, and a hardcoded exemption in `scripts/tests/agents.sh` hid
that from 2026-09-03 to 2026-09-23. The security row in `## After the plan` is `/code-review` now, and `/code-review`
has no security axis, so the row is only worth ticking if the dispatch names the boundary and asks
for the input tracing. ADR 0006 records what that gives up.

**A SKILL.md body gets positional-argument expansion at load.** A dollar sign followed by a single
digit is replaced by the word at that position in the skill's arguments, so money in a skill body is
written `USD 3.90`, and `scripts/tests/agents.sh` fails any skill or agent definition carrying the
sequence. Named variables such as `$CAP_DIR` are untouched.

The round cap, why crews run in the background, cost, and what the two expensive crews were are in
`docs/captain.md`. **Read it before changing the loop.**

### Settings and permissions

`settings.json` is verified against Claude Code 2.1.231, installed via Homebrew cask (trails npm by
~20 versions; `autoUpdates` has no effect). Permission rules, the deny/ask/allow layering, the
allowlist derivation, and the version-gated settings are documented in
`docs/claude-permissions.md`. **Read that file before editing `settings.json`.**

### Hooks

Six hooks in `settings.json`. **A hook whose `command` path is wrong fails silently**, so
`scripts/tests/settings.sh` asserts every `command` resolves to an executable both in the package
and at its stowed path. Run it after touching `settings.json` or renaming anything a hook calls.

**Never give a Stop hook a `timeout` shorter than the work it runs**, and do slow post-turn work
with `asyncRewake` rather than a synchronous Stop hook.

The inventory, each hook's contract, which events deliver plain stdout, and the two rules learned
the hard way are in `docs/claude-context.md`. **Read it before changing a hook.**

### Self-improvement

`/self-improve` audits the setup through four lenses and ranks findings; picking is yours, and what
you pick goes to a workstream and `/planning`.

`scripts/improve/improve-record.sh` is the record behind it, append-only at
`~/.claude/improve/record.jsonl`. **An entry names the file it wants changed or it is refused.**
Three entries against one target is a design defect, and `cap-crews.sh list` prints that footer.

`docs/claude-improve.md` has the schema, the two design constraints and why the four lenses are the
four. **Read it before changing a lens, the record's fields, or the recurrence threshold.**

### Statusline

`statusline.sh` uses one `jq` fork and bash integer comparison. **Do not add per-render
subprocesses.** It renders context and session cost, and crew spend rides in a bracket after the
cost when the repo has a workstream pointer.

The context segment colours on absolute tokens, green below 200k, yellow at 200k, red plus an action
hint at 300k, and **the percentage is measured against that 300k budget rather than the context
window**.

Thresholds, the 967k auto-compact derivation, the measurements behind the crew bracket and the
segments that were tried and removed are in `docs/claude-context.md`. **Read it before changing a
threshold.**

## Crews

Role dispatch over native agent definitions. A crew is an ordinary Claude Code session wearing one
of the five role definitions in `claude/.claude/agents/`, started by
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
