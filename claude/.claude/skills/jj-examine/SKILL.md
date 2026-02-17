---
name: jj-examine
description: AUTO-INVOKE when examining changes, preparing commits, resolving conflicts, or comparing revisions in a jj repository. Use instead of github-examining-changes for any jj repo.
disable-model-invocation: true
---

# Examining Changes in jj

**Core Principle:** Fast then slow. Run overview commands first (parallel), deep commands after reviewing output.

**Announce at start:** "I'm using the jj-examine skill to examine changes."

## jj vs git Quick Map

| git | jj |
|-----|----|
| `HEAD` | `@` |
| `master`/`main` | `trunk()` |
| `git diff --staged` | `jj diff` (no staging area) |
| `git log master..HEAD` | `jj log -r "trunk()..@"` |
| `git diff master...HEAD` | `jj diff --from trunk()` |
| `git show <sha>` | `jj show <change-id>` |
| `git status` | `jj status` |

## Fast Commands (run in parallel)

```bash
jj status & jj diff --stat & jj log -r "trunk()..@" --no-graph & wait
```

## Key Commands Reference

| Command | Purpose |
|---------|---------|
| `jj diff` | All changes in working copy |
| `jj diff --stat` | Summary of changed files |
| `jj diff -r <id>` | Changes in specific revision |
| `jj diff --from trunk()` | PR scope diff |
| `jj show <id>` | Change details + description |
| `jj log -r "trunk()..@"` | All commits in PR scope |
| `jj log -r "trunk()..@" --no-graph` | Same, no graph decoration |

## Revsets Cheat Sheet

| Revset | Meaning |
|--------|---------|
| `@` | Working copy (current change) |
| `@-` | Parent of working copy |
| `trunk()` | Main branch (master/main) |
| `trunk()..@` | All changes for PR |
| `all:trunk()..@` | Explicit: all commits in range |

## Conflict Resolution

1. `jj status` — look for `C` marker on files
2. `jj resolve --list` — see all conflicted files
3. `jj resolve <file>` — resolve file (opens nvimdiff)
4. `jj status` — verify no remaining conflicts

## Before Commit/PR Workflow

**Phase 1 — Fast overview (parallel):**
```bash
jj status & jj diff --stat & jj log -r "trunk()..@" --no-graph & wait
```

**Phase 2 — Deep examine (sequential, based on Phase 1):**
```bash
jj diff --from trunk()          # Full PR diff
jj diff -r <id>                 # Specific change
jj show <id>                    # Specific change + message
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `git diff`, `git log` in jj repos | Use `jj diff`, `jj log` |
| Using `HEAD` in revsets | Use `@` |
| Using `master..HEAD` syntax | Use `"trunk()..@"` revset |
| Running full diff before `--stat` | Always `--stat` first |
| Looking for staging area | jj has none — `jj diff` shows all changes |
