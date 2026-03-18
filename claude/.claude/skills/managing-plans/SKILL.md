---
name: managing-plans
description: AUTO-INVOKE when moving plans between statuses, checking plan progress, renaming plan files, listing plans, or performing plan lifecycle operations.
disable-model-invocation: false
---

# Plan Lifecycle Management

## Status Workflow

| Status | Meaning |
|--------|---------|
| `backlog` | Ideas, not yet detailed |
| `draft` | Being written, not finalized |
| `todo` | Approved, ready to implement |
| `active` | Currently being implemented |
| `done` | Completed and verified |
| `archived` | Old or superseded |

**Flow:** draft → todo → active → done

## Helper Scripts

```bash
plan-status.sh                    # Count plans per status
plan-list.sh [status]             # List plans (all or filtered)
plan-move.sh <filename> <status>  # Move plan to new status
```

## File Naming Convention

**Filename format:** `YYYY-MM-DD-<feature-name>.md` (kebab-case, descriptive)
- Good: `2026-02-19-jj-examine-skill.md`
- Bad: `luminous-forging-pizza.md` ← **rename these immediately**

**CRITICAL RULE:** When plan mode auto-generates a random filename, **rename it before exiting plan mode.**
```bash
mv ~/.claude/plans/draft/random-name.md ~/.claude/plans/draft/2026-02-19-feature-name.md
```

## Progress Tracking in Active Plans

Mark steps as work progresses:
```markdown
## Steps
- ✅ Step one — completed
- 🔴 Step two — HIGH PRIORITY, in progress
- Step three — pending
```

## Lifecycle Commands

```bash
# Start a new plan
plan-move.sh 2026-02-19-my-feature.md draft   # already in draft

# Approve and queue
plan-move.sh 2026-02-19-my-feature.md todo

# Start implementation
plan-move.sh 2026-02-19-my-feature.md active

# Complete
plan-move.sh 2026-02-19-my-feature.md done
```

## Common Operations

- **List all plans:** `plan-list.sh`
- **List by status:** `plan-list.sh active`
- **Check counts:** `plan-status.sh`
- **Move after approval:** `plan-move.sh <filename> todo`
- **Start work:** `plan-move.sh <filename> active`
- **Mark done:** `plan-move.sh <filename> done`
- **Archive old plans:** `plan-move.sh <filename> archived`
