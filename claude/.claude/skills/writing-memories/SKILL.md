---
name: writing-memories
description: Use after completing a complex task, discovering a recurring pattern, learning a user preference, or finding a non-obvious solution. Guides saving learnings to the correct memory files.
disable-model-invocation: true
---

# Writing Memories

Use this skill when you want to preserve a learning across sessions.

## Trigger Conditions

- Completed a complex or multi-session task
- Discovered a pattern that would recur across projects
- Learned a user preference or workflow decision
- Found a non-obvious solution to a recurring problem

## Memory File Locations

**MEMORY.md** — `~/.claude/projects/<hash>/memory/MEMORY.md`
- Loaded into every system prompt (lines after ~200 are truncated)
- Keep concise: stable patterns, key decisions, links to topic files
- Do NOT duplicate content already in CLAUDE.md

**Topic files** — `~/.claude/projects/<hash>/memory/<topic>.md`
- Detailed notes linked from MEMORY.md
- Examples: `debugging.md`, `patterns.md`, `architecture.md`

## What to Save

- Stable patterns confirmed across multiple interactions
- Key architectural decisions and important file paths
- User preferences for workflow, tools, communication style
- Solutions to recurring problems and debugging insights

## What NOT to Save

- Session-specific context (current task, in-progress work, temp state)
- Unverified conclusions drawn from reading a single file
- Content that duplicates or contradicts CLAUDE.md instructions
- Speculative or incomplete information

## How to Save

Use the helper script when available:
```bash
~/.claude/scripts/save-learning.sh
```

Or write directly with the Write/Edit tools to the memory files above.

## MEMORY.md Format

```markdown
# Memory

## <Topic>
- Key pattern or decision
- Link to detail: see `topic.md`

## User Preferences
- Prefers X over Y for Z
```

Keep each entry to 1-2 lines. Link to topic files for detail.

## Monthly Review

Run `~/.claude/scripts/review-memory.sh` (first Monday of month) to prune stale entries.
