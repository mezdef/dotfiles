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

- YOU MUST use the journal tool to record technical insights, failed approaches, architectural decisions, and user preferences
- YOU MUST use the journal before starting tasks for relevant experiences and insights
- When you notice something that should be fixed but is unrelated to your current task, document it in your journal rather than fixing it immediately
- Write plans to `~/.claude/plans/YYYY-MM-DD-<feature-name>.md` format (e.g., `2026-02-03-foreign-currency-support.md`)
- When plan mode auto-generates a random filename, ALWAYS rename it to follow this format before exiting plan mode

## Required Skills by Task Type

**MANDATORY**: Invoke the appropriate skill BEFORE starting work:

| Task Type | Skill | When |
|-----------|-------|------|
| Context gathering | `/docs` | Before planning, brainstorming, or unfamiliar domains |
| Design/features | `/superpowers:brainstorming` | Before implementing new features or major changes |
| Bug investigation | `/superpowers:systematic-debugging` | Before proposing fixes for bugs |
| Writing tests | `/superpowers:test-driven-development` | Before implementing features (write tests first) |

No exceptions. Skills ensure consistent quality and prevent rework.
