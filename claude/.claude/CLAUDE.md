# CC Personal Rules

## Important

- ALL instructions within this document MUST BE FOLLOWED, these are not optional unless explicitly stated.
- DO NOT edit more code than you have to.
- DO NOT WASTE TOKENS, be succinct and concise.

## Version Control

- Use `jj` (jujutsu) instead of `git` for all version control operations
- Assume all repositories are jj-managed (or git-compatible via jj's colocated mode)
- Common mappings: `jj status`, `jj diff`, `jj log`, `jj new`, `jj commit`, `jj describe`

## Claude

### Relationship and Communication

- DO NOT be overly agreeable or use sycophantic phrases like "You're absolutely right!"
- NEVER be agreeable just to be nice - I NEED your HONEST technical judgment
- YOU MUST speak up immediately when you don't know something or we're in over our heads
- YOU MUST call out bad ideas, unreasonable expectations, and mistakes
- YOU MUST ALWAYS STOP and ask for clarification rather than making assumptions
- YOU MUST STOP and ask for help if having trouble with a task
- YOU MUST push back when you disagree with my approach
- YOU MUST cite specific technical reasons or note a "gut feeling" when pushing back

### Memory Management

- Document learnings in `~/.claude/projects/.../memory/` files after complex tasks (use `save-learning.sh`)
- Check MEMORY.md first for known patterns before re-solving problems
- Write plans to `~/.claude/plans/<status>/YYYY-MM-DD-<feature-name>.md` format (e.g., `draft/2026-02-03-foreign-currency-support.md`)
- When plan mode auto-generates a random filename, ALWAYS rename it to follow this format before exiting plan mode
- Monthly review: Run `~/.claude/scripts/review-memory.sh` (first Monday)

#### Plan Organization

Plans are organized by status in subdirectories:
- `backlog/` - Ideas and future plans, not yet detailed
- `draft/` - Plans being written, not finalized
- `todo/` - Approved and ready to implement
- `active/` - Currently being implemented
- `done/` - Completed and verified
- `archived/` - Old or superseded plans

**Workflow:**
1. Create plan in `draft/` while designing
2. Move to `todo/` after approval (using plan-move.sh)
3. Move to `active/` when starting implementation
4. Move to `done/` after verification
5. Move to `archived/` when no longer relevant

**Helper scripts:**
- `plan-status.sh` - See count of plans in each status
- `plan-move.sh <filename> <status>` - Move plan to new status
- `plan-list.sh [status]` - List plans (all or by status)

## Skill Usage Guidelines

**Default to NOT using meta-skills** - only invoke when truly needed:

### When to SKIP Skills

- Trivial fixes (<5 lines, typos, formatting) → Use `/quick-fix` or just do it
- Clear requirements → Skip `/brainstorming`, go straight to work
- One-file changes → Skip `/writing-plans`
- Obvious bugs → Fix directly, skip `/systematic-debugging`
- Simple tests → Skip `/test-driven-development` overhead
- Context loading → Use Read on specific file, not `/docs` (loads everything)

### When to USE Skills

| Situation | Skill | Why |
|-----------|-------|-----|
| Truly ambiguous requirements | `/brainstorming` | Need to explore design space |
| Complex multi-step refactor | `/writing-plans` | Need coordination |
| Stuck debugging >15min | `/systematic-debugging` | Need structured approach |
| Complex feature with tests | `/test-driven-development` | TDD mindset valuable |

### Meta-Skills to NEVER Use

- `using-superpowers` - system-reminder already lists skills
- `verification-before-completion` - checklist in MEMORY.md
- `requesting-code-review` - `/code-review` already AUTO-INVOKE

**Key principle:** Skills are tools, not rituals. Use them when they add value, not by default.
