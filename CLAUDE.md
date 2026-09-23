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
`sessions/`, `workers/`, `history.jsonl`, caches) is machine state and stays untracked.

Work-specific scripts physically live in the package but are gitignored, so they are stowed
locally without being published. See the gitignore block for the list.

Context budget, the workstream lifecycle contract, and the measurements behind both are in
`docs/claude-context.md`. **Read it before changing `statusline.sh` thresholds, the plan hooks, or
`workstream.sh`.** Token and cost accounting — the ledger, the price table, and the three
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

**Removal is two deletions, not one.** `fix` relinks anything installed but unlinked, so dropping
the package link alone restores the skill on the next run. Delete the `~/.agents/skills/<name>`
install and its `.skill-lock.json` entry too, then assert both in `scripts/tests/agents.sh`. The npx
`claude-handoff` went that way on 2026-09-23, replaced by the repo-owned `/handoff`: it spawned a
`claude --bg` agent, which is the opposite of handing off through `/clear`, and its sibling
`skills/productivity/handoff` writes to the OS temp dir against the path contract.

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

`claude/.claude/agents/*.md`, stowed to `~/.claude/agents/`. **A definition named after one of
Claude Code's own agents replaces it wholesale**, prompt, tools and model, because definitions
merge into a map keyed by the frontmatter `name:`. `Explore.md` is the one override here, for its
`model: haiku` pin. **Read `docs/workers.md` before changing a definition.**

### Planning

**Planning has one entry point: `/planning`.** It owns the process and what follows the plan.
`/writing-plans`, `/writing-design-docs` and `/workstreams` own the format, and `Plan` reaches
them itself.

**A SKILL.md body gets positional-argument expansion at load.** A dollar sign followed by a single
digit is replaced by the word at that position in the skill's arguments, so money in a skill body
is written `USD 3.90`. Named variables such as `$WORKSTREAM_DIR` are untouched.

### Settings and permissions

`settings.json` is verified against Claude Code 2.1.267, installed via Homebrew cask (trails npm by
~20 versions; `autoUpdates` has no effect). Permission rules, the deny/ask/allow layering, the
allowlist derivation, and the version-gated settings are documented in
`docs/claude-permissions.md`. **Read that file before editing `settings.json`.**

### Hooks

Seven hooks in `settings.json`. **A hook whose `command` path is wrong fails silently**, so
`scripts/tests/settings.sh` asserts every `command` resolves to an executable both in the package
and at its stowed path. Run it after touching `settings.json` or renaming anything a hook calls.

**Every repo gets a workstream, and an approved plan is filed into it by the hook, not by the
session.** `workstream-required.sh` on UserPromptSubmit is the only enforcement point that fires
in every mode. Plan mode picks its own path and no setting redirects it into `~/.claude/work`, so
`plan-lifecycle.sh` copies the plan out of `~/.claude/plans/<slug>.md` at PostToolUse.
**Do not turn this back into a gate.** A PreToolUse deny on `ExitPlanMode` works and is useless:
plan mode is read-only, so the session cannot satisfy it and every run burns the cap. Read
`docs/claude-context.md`'s **Plan mode owns its own path** before touching any of it.

**Never give a Stop hook a `timeout` shorter than the work it runs**, and do slow post-turn work
with `asyncRewake` rather than a synchronous Stop hook.

The inventory, each hook's contract, which events deliver plain stdout, and the two rules learned
the hard way are in `docs/claude-context.md`. **Read it before changing a hook.**

### Self-improvement

`/self-improve` audits the setup through four lenses and ranks findings; picking is yours, and what
you pick goes to a workstream and `/planning`.

`scripts/improve/improve-record.sh` is the record behind it, append-only at
`~/.claude/improve/record.jsonl`. **An entry names the file it wants changed or it is refused.**
Three entries against one target is a design defect, and `workers.sh list` prints that footer.

`docs/claude-improve.md` has the schema, the two design constraints and why the four lenses are the
four. **Read it before changing a lens, the record's fields, or the recurrence threshold.**

### Statusline

`statusline.sh` uses one `jq` fork and bash integer comparison. **Do not add per-render
subprocesses.** The line is `<vim mode> 󰚩 <model> (<effort>) | 󰮯 <tokens> (<pct>%) | $<cost>`, with
worker spend **right-aligned at the far edge** when the repo has a workstream pointer.

The context segment colours on absolute tokens, green below 140k, yellow at 140k, red at 200k, and
**the percentage is measured against that 200k budget rather than the context window**.

Right-alignment reads `$COLUMNS`, which Claude Code exports because it captures stdout rather than
attaching it to a tty. **The pad is measured against a plain copy of the left side, never the
coloured one**, or the ANSI bytes are counted as visible width.

The vim mode is the only built-in chrome row that can be suppressed, via
`statusLine.hideVimModeIndicator`; the script renders it instead. The background-shells counter and
the permission-mode indicator reach neither the payload nor a setting.

Thresholds, the 967k auto-compact derivation, the measurements behind the worker block and the
segments that were tried and removed are in `docs/claude-context.md`. **Read it before changing a
threshold or the line layout.**

## Workers

A worker is an ordinary session wearing one of the five role definitions in `agents/`, started by
`scripts/workstream/workers.sh`. `$WORKSTREAM_DIR` is the workstream `workstream.sh` returns.

**A session that dispatches workers does not read repo files.** No `Read`, `Grep`, `Glob`, `Edit` or
`jj diff` on anything in the repo, including while integrating, where the step is yours but the
reading is not. Reading is a dispatch.

**Never run `jj resolve`.** It opens an editor, the editor here is configured to fail, and a
stuck session looks alive from outside. Edit the conflict markers instead and let the next command
snapshot it.

**Read `docs/workers.md`** before changing a role definition, a script under `scripts/workstream/`, or the worker
statusline.

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
