---
name: git-examine
description: Use when preparing to create commits or PRs and need to understand what changed, verify scope, check for unintended changes, or identify issues before committing
disable-model-invocation: true
---

# Examining Changes Between Branches

## Overview

Before creating commits or PRs, efficiently examine changes to understand scope, identify issues, and write accurate descriptions. Use the right git/gh commands to get the information you need quickly.

**Core Principle:** Gather information in parallel when possible, sequentially when commands depend on each other.

**Announce at start:** "I'm using the github-examining-changes skill to examine branch changes."

## When to Use

Use this skill when:
- Preparing to create a commit
- Preparing to create a pull request
- Understanding what changed in a branch
- Reviewing changes before pushing
- Writing commit messages or PR descriptions
- Verifying no unintended changes

## Quick Reference Commands

**CRITICAL: Run fast commands FIRST, then slow commands based on what you learn.**

**Fast commands (parallel - run all at once with & and wait):**
```bash
git status &
git diff master...HEAD --stat &
git log master..HEAD --oneline &
wait
```

**Slow commands (sequential - only after reviewing fast command output):**
```bash
git diff master...HEAD                 # Full diff (run ONLY after --stat)
git diff master...HEAD -- path/to/file # Specific file
git show <commit-sha>                  # Specific commit
```

## Git Range Operators (Critical to Understand)

| Operator | Use With | Meaning | Example |
|----------|----------|---------|---------|
| `..` (two dots) | `git log` | Commits on current branch NOT on base | `git log master..HEAD` |
| `...` (three dots) | `git diff` | Diff between branches (merge base) | `git diff master...HEAD` |

**Common mistake:** Using `git log master...HEAD` (wrong - shows commits reachable by either)
**Correct:** Use `git log master..HEAD` to see commits on your branch

## Command Speed Reference

**Always run fast commands first, then decide what slow commands to run.**

| Speed | Commands | When to Use |
|-------|----------|-------------|
| **Fast** (<1s) | `git status`, `git diff --stat`, `git diff --name-only`, `git log --oneline` | First - get overview |
| **Slow** (seconds) | `git diff` (full), `git log -p`, `git blame` | Second - examine specific areas |

**Parallel execution syntax:**
```bash
# Run ALL independent commands together
git status &
git log master..HEAD --oneline &
git diff master...HEAD --stat &
wait  # Wait for all to complete
```

## Systematic Quality Checks

**Before every commit/PR, check for:**
```bash
# Check for debug code
git diff master...HEAD | grep -i "console\.log\|debugger\|TODO"

# Check for large files (over 500 lines changed)
git diff master...HEAD --stat | awk '$1 > 500 { print }'

# Check for deleted files
git diff master...HEAD --name-status | grep "^D"
```

## Essential Git Commands for Branch Examination

### 1. Understanding What Changed

**Get high-level overview:**
```bash
# Files changed with statistics
git diff master...HEAD --stat

# Just file names
git diff master...HEAD --name-only

# File names with status (A=added, M=modified, D=deleted)
git diff master...HEAD --name-status
```

**Output example:**
```
src/actions/transactions.ts    | 45 ++++++++++++++++--
src/lib/stripe/invoices.ts     | 23 +++------
tests/transactions.test.ts     | 89 +++++++++++++++++++++++++++++++++++
3 files changed, 138 insertions(+), 19 deletions(-)
```

### 2. Examining Specific Files

**See changes in one file:**
```bash
# Full diff for specific file
git diff master...HEAD -- src/actions/transactions.ts

# Just see if file was added/modified/deleted
git diff master...HEAD --name-status | grep transactions.ts

# See file at specific commit
git show HEAD:src/actions/transactions.ts
```

**Compare specific sections:**
```bash
# Show function changes only (uses git's pattern matching)
git diff master...HEAD -- src/actions/transactions.ts | grep -A 10 "function"

# Show changes with more context (default is 3 lines)
git diff -U10 master...HEAD -- src/actions/transactions.ts
```

### 3. Understanding Commit History

**List commits between branches:**
```bash
# One line per commit (fast scan)
git log master..HEAD --oneline

# With file statistics
git log master..HEAD --stat

# With full diff for each commit
git log master..HEAD -p

# With graph visualization
git log master..HEAD --oneline --graph --decorate

# Only commits affecting specific file
git log master..HEAD -- src/actions/transactions.ts
```

**Output example:**
```
f465b7c29 MD - Use Drizzle batch insert for Transaction Events
2d4e617c5 MD - Enable auto-charging if customer has saved credit card details
dc3e05c44 RDC - Remove unneeded Jsonify type wrappers
```

### 4. Examining Individual Commits

**See full commit details:**
```bash
# Show commit with diff
git show <commit-sha>

# Show commit message only
git log -1 <commit-sha>

# Show files changed in commit
git show --name-status <commit-sha>

# Show commit with statistics
git show --stat <commit-sha>
```

### 5. Finding Specific Changes

**Search in diffs:**
```bash
# Find commits that changed a specific string
git log master..HEAD -S "createTransactionEvent"

# Find commits with specific message
git log master..HEAD --grep "transaction"

# Find changes to specific function
git log master..HEAD -L :functionName:path/to/file.ts
```

**Search in current diff:**
```bash
# See all lines that add/remove specific pattern
git diff master...HEAD | grep "^[+-].*createTransactionEvent"

# Count occurrences of a pattern in changes
git diff master...HEAD | grep -c "createTransactionEvent"
```

## Using GitHub CLI (gh) for Branch Examination

### 1. Examining PRs

**View PR information:**
```bash
# View PR in terminal
gh pr view <number>

# View PR in browser
gh pr view <number> --web

# See PR status checks
gh pr checks <number>

# See PR diff
gh pr diff <number>

# See PR comments
gh pr view <number> --comments
```

### 2. Comparing Branches

**Compare without creating PR:**
```bash
# Compare current branch to master
gh pr view --web $(gh pr create --title "temp" --body "temp" --draft)

# Or view comparison URL
echo "https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/compare/master...$(git branch --show-current)"
```

### 3. Listing Changes

**See related PRs:**
```bash
# List all PRs
gh pr list

# List PRs for specific branch
gh pr list --head <branch-name>

# List your PRs
gh pr list --author "@me"

# List PRs with specific label
gh pr list --label "bug"
```

## Efficient Examination Workflow

### Before Creating Commit

**ALWAYS examine BEFORE committing. Never commit then examine.**

**Fast commands first (parallel):**
```bash
git status &
git diff --stat &
git diff --staged --stat &
wait
```

**Then slow commands (based on what you learned):**
```bash
git diff               # Full unstaged changes
git diff --staged      # Full staged changes
```

### Before Creating PR

**ALWAYS examine BEFORE creating PR. Never create PR then examine.**

**Phase 1: Fast parallel commands (get overview):**
```bash
git status &
git log master..HEAD --oneline &
git diff master...HEAD --stat &
wait
```

**Output gives you:**
- Untracked files (status) - verify nothing unintended
- Commits for PR (log) - summarize in PR description
- Files changed summary (stat) - understand scope

**Phase 2: Quality checks (parallel):**
```bash
git diff master...HEAD | grep -i "console\.log\|debugger\|TODO" &
git diff master...HEAD --stat | awk '$1 > 500 { print }' &
git diff master...HEAD --name-status | grep "^D" &
wait
```

**Phase 3: Deep dive slow commands (sequential, based on Phase 1):**
```bash
# Examine full diff for specific files
git diff master...HEAD -- src/actions/transactions.ts
git diff master...HEAD -- src/lib/stripe/invoices.ts

# Examine specific commits
git show <commit-sha>
```

## Advanced Techniques

### 1. Filtering by File Type

```bash
# Only JavaScript/TypeScript files
git diff master...HEAD --stat -- '*.ts' '*.tsx' '*.js' '*.jsx'

# Exclude test files
git diff master...HEAD --stat -- . ':(exclude)*test*'

# Only files in specific directory
git diff master...HEAD --stat -- src/actions/
```

### 2. Understanding Impact

```bash
# Count total lines changed
git diff master...HEAD --stat | tail -1

# Lines added/removed per file
git diff master...HEAD --numstat

# See biggest changes
git diff master...HEAD --stat | sort -k 3 -n -r | head -10
```

**Output example:**
```
23      5       src/actions/transactions.ts
89      12      tests/transactions.test.ts
3       45      src/lib/stripe/invoices.ts
```
(23 added, 5 removed in first file)

### 3. Comparing Specific Points

```bash
# Compare branch start vs current
git diff $(git merge-base master HEAD)..HEAD

# Compare two specific commits
git diff <commit1> <commit2>

# Compare file between two commits
git diff <commit1> <commit2> -- path/to/file
```

### 4. Visual Inspection

```bash
# Word-level diff (better for small changes)
git diff master...HEAD --word-diff

# Show whitespace changes explicitly
git diff master...HEAD --ws-error-highlight=all

# Ignore whitespace changes
git diff master...HEAD -w
```

## Common Patterns

### Pattern 1: Quick PR Prep

```bash
# Everything you need for PR description (run in parallel)
git status &
git log master..HEAD --oneline &
git diff master...HEAD --stat &
wait

# Then examine specific files
git diff master...HEAD
```

### Pattern 2: Find What Changed in Specific Area

```bash
# See commits affecting authentication
git log master..HEAD --oneline -- src/auth/

# See actual changes
git diff master...HEAD -- src/auth/
```

### Pattern 3: Verify No Unintended Changes

```bash
# Check for debug code
git diff master...HEAD | grep -i "console.log\|debugger\|TODO"

# Check for large file additions
git diff master...HEAD --stat | awk '$1 > 500 { print }'

# Check for deleted important files
git diff master...HEAD --name-status | grep "^D"
```

### Pattern 4: Understanding Complex Changes

```bash
# See change evolution through commits
git log master..HEAD -p -- src/actions/transactions.ts

# See who changed what (blame with range)
git blame -L 100,200 src/actions/transactions.ts

# See file history
git log --follow -- src/actions/transactions.ts
```

## Red Flags When Examining Changes

Stop and investigate if you see:

- **Unintended files changed**: Files you didn't mean to modify
- **Large whitespace changes**: May hide real changes
- **Deleted important files**: Could break functionality
- **Many files affected**: May indicate scope creep
- **Debug code present**: console.log, debugger statements
- **TODO/FIXME comments**: Unfinished work
- **Dependency changes**: package.json without documentation
- **Schema changes**: Database migrations without SQL in PR
- **Breaking changes**: Function signature changes without notes

## Integration with PR Creation

**Use examination results to write:**

1. **Summary** - From `git log master..HEAD --oneline`
2. **Key Features** - From `git diff master...HEAD --stat`
3. **Changes section** - From `git diff master...HEAD --name-status`
4. **Technical details** - From examining specific `git show <commits>`
5. **Breaking changes** - From `git diff master...HEAD` review
6. **Test plan** - From understanding scope via `--stat`

## Performance Tips

**IRON RULE: Fast commands first, slow commands second, parallel whenever possible.**

**Fast commands (< 1 second) - Always run these first:**
```bash
git status &
git diff --stat &
git diff --name-only &
git log --oneline &
wait
```

**Slow commands (seconds) - Run ONLY after reviewing fast command output:**
- `git diff master...HEAD` (full diff) - ONLY run after --stat shows manageable scope
- `git log -p` (diff for each commit) - ONLY for specific commit investigation
- `git blame` (analyze history) - ONLY for specific line investigation

**Anti-pattern:** Running `git diff master...HEAD` first without knowing scope from `--stat`

## Checklist: Before Creating PR

**Phase 1: Fast overview (run in parallel with & and wait):**
- [ ] Ran `git status` - no unintended changes
- [ ] Ran `git diff master...HEAD --stat` - understand scope
- [ ] Ran `git log master..HEAD --oneline` - know all commits (two dots!)

**Phase 2: Quality checks (run in parallel):**
- [ ] Verified no debug code: `git diff master...HEAD | grep -i "console\.log\|debugger\|TODO"`
- [ ] Checked for large files: `git diff master...HEAD --stat | awk '$1 > 500 { print }'`
- [ ] Checked for deleted files: `git diff master...HEAD --name-status | grep "^D"`

**Phase 3: Deep examination (sequential, based on Phase 1):**
- [ ] Examined key file changes with `git diff master...HEAD -- <file>`
- [ ] Checked for breaking changes
- [ ] Confirmed database changes have migrations
- [ ] Noted any files needing special explanation

**Ready to create PR:**
- [ ] Have commit summaries for PR description
- [ ] Have file statistics for scope
- [ ] Have quality check results
- [ ] Ready to write comprehensive PR description

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Running `git diff` before `git diff --stat` | Wastes time reading full diff before knowing scope | Always run --stat first |
| Using `git log master...HEAD` | Wrong operator - shows commits reachable by either branch | Use `git log master..HEAD` (two dots) |
| Running commands sequentially when parallel works | Slow workflow | Use `&` and `wait` for independent commands |
| Not checking for debug code | console.log, debugger in production | Always grep diff before PR |
| Examining changes AFTER committing | Can't write accurate commit message | Examine FIRST, then commit |
| Skipping examination for "simple" changes | One-line changes can break systems | Always examine, always |

## Integration with Other Skills

**Typical workflow:**
1. Use **this skill** to examine changes BEFORE committing
2. Use **github-commits-and-prs** to create commit/PR
3. Use **verification-before-completion** to verify tests pass
4. Use **requesting-code-review** if needed

## Tips

- **Start broad, then narrow**: Run fast overview commands first, then examine specific files
- **Look for patterns**: Similar changes across files may indicate refactoring
- **Check every commit**: Don't just look at final diff, understand the journey
- **Verify intentions**: Ensure changes match what you meant to do
- **Document surprises**: Note anything unexpected for PR description
- **Use parallel execution**: Run independent git commands concurrently
- **Save time with --stat**: Get overview without reading full diffs
- **Leverage --name-status**: Quickly identify added/modified/deleted files

## Examples

### Example 1: Quick Commit Prep

```bash
# See what's changed
git status
git diff --stat

# Output shows 3 files modified in src/actions/
# Examine them
git diff src/actions/
```

### Example 2: Comprehensive PR Prep

```bash
# Phase 1: Fast overview (parallel with & and wait)
git status &
git log master..HEAD --oneline &
git diff master...HEAD --stat &
wait

# Output shows:
# - 2 commits
# - 5 files changed
# - Main changes in src/actions/ and tests/

# Phase 2: Quality checks (parallel)
git diff master...HEAD | grep -i "console\.log\|debugger\|TODO" &
git diff master...HEAD --stat | awk '$1 > 500 { print }' &
git diff master...HEAD --name-status | grep "^D" &
wait

# Phase 3: Deep dive into main areas (sequential based on Phase 1)
git diff master...HEAD -- src/actions/
git diff master...HEAD -- tests/
```

### Example 3: Understanding Legacy Code Changes

```bash
# See what changed in authentication
git log master..HEAD -- src/auth/

# View specific commits
git show abc123
git show def456

# Compare old vs new for specific file
git diff master...HEAD -- src/auth/session.ts
```

### Example 4: Finding Bug Introduction

```bash
# Search for when bug was introduced
git log master..HEAD -S "problematicFunction"

# See the actual changes
git show <commit-sha>

# Check if tests were added
git log master..HEAD -- tests/ --stat
```
