---
name: writing-plans
description: AUTO-INVOKE when writing, creating, or updating a plan; when entering plan mode; when moving a plan between statuses; or when checking plan progress. Covers naming conventions, file location, status workflow, and plan format for this repo.
disable-model-invocation: true
---

# Plan Writing & Management

## Location & Naming

**Base dir:** `~/.claude/plans/<status>/`

**Filename format:** `YYYY-MM-DD-<feature-name>.md` (kebab-case, descriptive)
- Good: `2026-02-19-jj-examine-skill.md`
- Bad: `luminous-forging-pizza.md` ← **rename these immediately**

**CRITICAL RULE:** When plan mode auto-generates a random filename, **rename it before exiting plan mode.**
```bash
mv ~/.claude/plans/draft/random-name.md ~/.claude/plans/draft/2026-02-19-feature-name.md
```

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

## Standard Plan Format

```markdown
# Feature Title

> **For Claude:** Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** One sentence describing what this builds.

## Context
Why this is needed. What problem it solves. What exists today.

## What to Build
Concrete description of the output. Scope boundaries.

## Implementation Steps

### Task 1: Name

**Files:**
- Modify: `exact/path/to/file.ts:line`
- Create: `exact/path/to/new-file.ts`

1. Do X (exact command or code snippet)
2. Verify with: `<exact command>` — expected: `<output>`
3. `jj commit -m "feat: description"`

## Critical Files
- `path/to/file.ts` — why it matters

## Verification
- How to confirm it works
- Tests to run
```

**Step quality bar:** Each step is 2-5 minutes. Exact file paths. Complete code, not "add validation". Exact commands with expected output.

## Progress Tracking in Active Plans

Mark steps as work progresses:
```markdown
## Steps
- ✅ Step one — completed
- 🔴 Step two — HIGH PRIORITY, in progress
- Step three — pending
```

## When to Write a Plan

**Write a plan when:**
- Multi-file changes (>3 files)
- Architectural decisions with real trade-offs
- Tasks that will span multiple sessions
- User explicitly asks for one

**Skip the plan when:**
- Single-file changes
- Obvious bug with clear fix
- Trivial feature (<5 lines)

## After Writing a Plan

Offer execution choice:

> "Plan saved to `~/.claude/plans/draft/<filename>.md`. Two options:
> 1. **Subagent-driven (this session)** — fresh subagent per task, review between each (`superpowers:subagent-driven-development`)
> 2. **Parallel session** — open new session, use `superpowers:executing-plans`"

Then move the plan to `todo` status and wait for approval before starting.

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
