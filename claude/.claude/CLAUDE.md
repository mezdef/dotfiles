# CC Personal Rules

## Important
- Follow ALL instructions in this document.
- DO NOT edit more code than necessary.
- DO NOT WASTE TOKENS — be succinct and concise.

## Version Control
- Use `jj` for all version control (git-compatible via colocated mode)
- Common: `jj status`, `jj diff`, `jj log`, `jj new`, `jj commit`, `jj describe`
- **Always create a new changeset before making changes** — run `jj new -m "wip - <description>"` before editing files. Never modify files on an existing changeset unless explicitly asked to amend it.

## Communication
- No sycophantic agreement — give honest technical judgment.
- Speak up when you don't know something or the approach is wrong.
- Ask for clarification rather than making assumptions.
- Push back with specific technical reasons or note a "gut feeling."

## Memory & Plans
- Check MEMORY.md for known patterns before re-solving problems.
- Save learnings after complex tasks → use `/writing-memories` skill.
- Plans: `~/.claude/plans/<status>/YYYY-MM-DD-<feature-name>.md`
- When plan mode auto-generates a filename, rename before exiting.
- Plan statuses: backlog / draft / todo / active / done / archived
- Scripts: `~/.claude/scripts/plan-status.sh`, `~/.claude/scripts/plan-move.sh <file> <status>`, `~/.claude/scripts/plan-list.sh [status]`

## Skill Usage
Default to NOT using meta-skills — only invoke when they add value.

**Project overrides this default.** When a project's CLAUDE.md lists MANDATORY skills (e.g. `/code-implement`, `/code-review`), follow the project — those are not optional and they supersede the "skip" rules below.

**Skip:** trivial fix → `/writing-code-quick` or just do it · clear requirements → skip `/brainstorming` · one-file change → skip `/writing-plans` · obvious bug → fix directly · specific doc → use Read, not `/docs`

**Use when:** ambiguous requirements → `/brainstorming` · complex multi-step → `/writing-plans` · stuck >15min → `/systematic-debugging` · complex feature + tests → `/test-driven-development`

**Never use:** `using-superpowers` · `verification-before-completion` · `requesting-code-review`
