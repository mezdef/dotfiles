---
name: git-commit
description: Use when creating git commits or GitHub pull requests, need to write commit messages following project conventions, create comprehensive PR descriptions, or understand commit/PR structure requirements
disable-model-invocation: true
---

# GitHub Commits and Pull Requests

## Overview

Write clear, informative commit messages and comprehensive pull request descriptions that follow project conventions and help reviewers understand the changes. PRs are always created in draft mode and should be marked as ready for review once all checks pass.

**Announce at start:** "I'm using the github-commits-and-prs skill to create this commit/PR."

## When to Use

Use this skill when:
- Creating a git commit
- Creating a GitHub pull request
- Amending commit messages
- Writing release notes

## Critical Prerequisite

**ALWAYS examine changes BEFORE creating commits or PRs.**

**Required workflow:**
1. **FIRST:** Use **github-examining-changes** skill to examine all changes
2. **THEN:** Use **this skill** to create commit/PR

**Never:**
- Create commit without examining changes first
- Create PR without examining full branch changes first
- Write commit message before understanding what changed
- Write PR description before reviewing all commits

## Commit Message Format

### Structure

```
INITIALS - Brief description of change


```

### Rules

**First line (required):**
- Start with your initials (e.g., "MD", "RDC", "WC", "FH")
- Space, dash, space
- Brief, imperative description (50-72 chars max)
- No period at end

**Body (optional):**
- Blank line after first line
- Explain WHAT and WHY, not HOW
- Wrap at 72 characters
- Use bullet points for multiple items


### Good Examples

```
MD - Add proper typing for TransactionEvent types

MD - Enable auto-charging if customer has saved credit card details

RDC - Remove unneeded Jsonify type wrappers

FH - Update statusLeadsSignups to camelCase

WC - Add ability to download duplicates to CSV
```

### Bad Examples

```
❌ fixed bug
❌ Update files
❌ MD - Implemented the new feature that allows users to do X with Y
❌ refactored code (not imperative mood)
❌ MD - Fixed the thing. (vague)
```

### Commit Message Guidelines

**Imperative mood:**
- "Add feature" not "Added feature"
- "Fix bug" not "Fixed bug"
- "Update component" not "Updated component"

**Be specific:**
- "Fix null pointer in payment processing" ✓
- "Fix bug" ✗
- "Add validation to email field" ✓
- "Update form" ✗

**Focus on WHAT changed:**
- "Add batch insert for transaction events" ✓
- "Refactor database code" ✗
- "Extract payment method logic into separate file" ✓
- "Improve code organization" ✗

**When to add body:**
- Complex changes needing context
- Breaking changes (explain migration path)
- Bug fixes (explain root cause)
- Performance improvements (explain benchmarks)
- Security fixes (explain vulnerability)

## Pull Request Structure

### Template

```markdown
## Summary

[2-3 sentences explaining what this PR does and why. Focus on the problem being solved and the value delivered.]

## Key Changes

- **Feature 1**: Brief description of what was added/changed
- **Feature 2**: Brief description of what was added/changed
- **Fix 1**: What was broken and how it's fixed

## Technical Notes

[Optional - only include if there are important technical details]

- Architecture or design pattern changes
- New dependencies or libraries added
- Performance considerations
- Security improvements

## Database Changes

[If applicable]

```sql
-- Migration details
ALTER TABLE "TableName" ADD COLUMN "column_name" type;
```

## Breaking Changes

[If applicable - CRITICAL section]

**Before:**
```typescript
oldFunction(param1);
```

**After:**
```typescript
newFunction(param1, param2);
```

**Migration:**
1. Update all call sites to use new signature
2. Run database migration
3. Update environment variables

## Test Plan

- [ ] Core functionality tested
- [ ] Edge cases verified
- [ ] Code quality checks passed (prettier, lint, type checking)
- [ ] Existing functionality still works

## UI Screenshots

[If applicable - include for any UI/visual changes]

**Before:**

![before](url-to-screenshot)

**After:**

![after](url-to-screenshot)

---
```

**Note:** File-level changes are visible in the GitHub diff view. Focus the PR description on the "what" and "why" rather than exhaustive file listings.
### PR Title Format

**Pattern:** `[Ticket-ID]: Brief description of changes`

Examples:
- `LM-2: Add Job Claim Transaction API Endpoint with Auto Top-Up & Rollover`
- `Fix JobPack status and Stripe customer address handling`
- `Sync Finchly Sign Up Enquiries to Salesforce`

**Rules:**
- Use title case
- Be specific and descriptive
- Include ticket reference if applicable
- Keep under 72 characters if possible

## Writing Process

**CRITICAL: Always use github-examining-changes skill FIRST to examine changes. Never skip this step.**

### For Commits

**Step 1: Check project conventions (if first commit in project)**
```bash
git log --oneline -20  # See recent commit message patterns
```
Identify the project's commit message format (initials, style, etc.)

**Step 2: Examine changes (use github-examining-changes skill)**
```bash
git status &
git diff --stat &
git diff --staged --stat &
wait

# Then review actual changes
git diff
git diff --staged
```

**Step 3: Determine scope**
- Single feature/fix? One commit.
- Multiple unrelated changes? Separate commits.

**Step 4: Write message**
- Start with your initials (from Step 1)
- Use imperative mood
- Be specific about WHAT changed

**Step 5: Add body if needed**
- Explain WHY for complex changes
- Provide context for reviewers
- Reference related issues/PRs
- Add Co-Authored-By line

### For Pull Requests

**Step 1: Examine ALL changes (use github-examining-changes skill)**

**Phase 1: Fast parallel commands**
```bash
git status &
git log master..HEAD --oneline &
git diff master...HEAD --stat &
wait
```

**Phase 2: Quality checks (parallel)**
```bash
git diff master...HEAD | grep -i "console\.log\|debugger\|TODO" &
git diff master...HEAD --stat | awk '$1 > 500 { print }' &
git diff master...HEAD --name-status | grep "^D" &
wait
```

**Phase 3: Deep dive (sequential)**
```bash
# Review full diff or specific files based on Phase 1 results
git diff master...HEAD -- <specific-files>
```

**Step 2: Write Summary**
- What problem does this solve?
- What value does it deliver?
- Keep it brief (2-3 sentences)

**Step 3: List Key Changes**
- Bullet points of main features/fixes/changes
- Focus on WHAT changed, not WHERE
- Brief description for each
- GitHub diff shows file-level details

**Step 4: Add Technical Notes** (if applicable)
- Architecture or design pattern changes
- New dependencies or libraries
- Performance considerations
- Security improvements
- Database migrations (with SQL)
- Breaking changes (CRITICAL - always document these!)

**Step 5: Create Test Plan**
- Checklist of what was tested
- Include edge cases
- Note code quality checks

**Step 6: Add UI Screenshots** (if applicable)
- Include for any visual or UI changes
- Show before/after comparisons
- Upload images to GitHub and use markdown image syntax

**Step 7: Create draft PR**
- Push branch and create draft PR
- Verify all information is correct
- Mark as ready for review when all checks pass

## Quality Checklist

### Commit Messages

Before committing:
- [ ] Starts with initials and dash
- [ ] Uses imperative mood ("Add" not "Added")
- [ ] Specific about what changed
- [ ] Under 72 characters (first line)
- [ ] Body explains WHY if needed

### Pull Requests

Before creating PR:
- [ ] Title is clear and descriptive
- [ ] Key features listed with brief descriptions
- [ ] All changed files documented with purpose
- [ ] Breaking changes clearly called out
- [ ] Database changes documented with SQL
- [ ] Test plan includes specific items tested
- [ ] Links to related issues/PRs

## Common Mistakes

### Workflow Mistakes (Most Critical)

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| Creating commit without examining changes | Can't write accurate message about unknown changes | ALWAYS use github-examining-changes FIRST |
| Creating PR without examining full branch | Can't write comprehensive description | ALWAYS examine with github-examining-changes |
| Not checking git log for conventions | Commit message doesn't match project style | Run `git log --oneline -20` first |
| Skipping quality checks | Debug code, TODOs reach production | Always grep diff for console.log, debugger, TODO |

### Commit Messages

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| "fixed bug" | Missing initials, vague, not imperative | "MD - Fix null pointer in payment processing" |
| "Updated the form component with new validation" | Past tense, too wordy | "MD - Add email validation to signup form" |
| "refactored" | Not specific | "MD - Extract payment logic into separate service" |
| "WIP" | Not descriptive | "MD - Add initial draft of invoice builder" |
| Not using project's initials format | Inconsistent with team style | Check git log first, use correct format |

### Pull Requests

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| One-line description | Not enough context | Add Summary with problem/solution |
| "See commit messages" | Not enough context | List key changes in PR description |
| No test plan | Can't verify changes | Add checklist of tested items |
| Missing breaking changes | Breaks production | Call out breaking changes prominently |
| No database migration docs | Deployment fails | Document SQL changes |
| Creating PR before examining full branch | Incomplete/inaccurate description | Use github-examining-changes FIRST |

## Git Commands

### Creating Commits

**Standard commit:**
```bash
git add <files>
git commit -m "$(cat <<'EOF'
INITIALS - Brief description

Optional longer explanation.


EOF
)"
```

**Review before committing:**
```bash
git status                  # See what's changed
git diff                    # See unstaged changes
git diff --staged           # See staged changes
git log -5                  # See recent commits
```

### Creating Pull Requests

**Using GitHub CLI:**
```bash
# Push branch first
git push -u origin <branch-name>

# Create draft PR with template
gh pr create --draft --title "Title" --body "$(cat <<'EOF'
## Summary
...


EOF
)"

# When ready for review (after all checks pass)
gh pr ready
```

**Review before PR:**
```bash
# See all commits for PR
git log origin/main..HEAD

# See all changes from main
git diff origin/main...HEAD

# See files changed
git diff --name-only origin/main...HEAD
```

## Integration with Other Skills

**REQUIRED workflow order:**
1. Use **verification-before-completion** to ensure tests pass
2. Use **github-examining-changes** to examine all changes (REQUIRED)
3. Use **this skill** to create commit/PR (this skill)
4. Use **requesting-code-review** if needed

**For large features:**
1. Create commits frequently (smaller, logical chunks)
2. Use **github-examining-changes** before EACH commit
3. Each commit should be self-contained
4. Use **github-examining-changes** again before PR to review full branch
5. PR description summarizes all commits
6. Reference related stories/bugs from Linear

**Never skip github-examining-changes - it's not optional.**

## Project-Specific Conventions

### Commit Message Style

**From recent history:**
- `MD - Use Drizzle batch insert for Transaction Events, type events properly`
- `RDC - Remove unneeded Jsonify type wrappers`
- `FH - Update statusLeadsSignups to camelCase`
- `WC - Add ability to download duplicates to CSV`

**Pattern observed:**
- Initials are 2-3 uppercase letters
- Common initials in this project: MD, RDC, FH, WC
- Descriptions are specific and technical
- Focus on implementation details

### PR Description Style

**From recent PRs:**
- Start with "## Summary" section
- Include "### Key Features" or "### Key Changes" subsection
- "## Changes" section with New/Modified/Deleted files
- "## Technical Implementation" for complex changes
- "## Database Changes" with SQL when applicable
- "## Breaking Changes" when applicable (IMPORTANT)
- "## Test Plan" with checkboxes
- "## Impact" for significant changes

### Code Review Integration

**When ready for review:**
1. Ensure all tests pass
2. Run code quality checks (lint, prettier, type check)
3. Create PR with comprehensive description
4. Link to Linear issues/stories
5. Request review from team

## Red Flags

Stop and revise if you see:

**Commit messages:**
- Missing initials
- Past tense ("Added", "Fixed")
- Vague descriptions ("Update code", "Fix bug")
- Missing Claude footer
- Over 72 characters (first line)

**Pull requests:**
- No Summary section
- No test plan
- Breaking changes not highlighted
- Database changes not documented
- Missing Claude footer
- Files changed not explained

## Examples

### Complete Commit Example

```
MD - Add proper typing for TransactionEvent types

Replace generic string type with TransactionEventType union
containing all 34 possible event types. This provides type safety
and autocomplete for all transaction event creation calls.

Updated CreateTransactionEventParams interface to use the new type.
Fixed type inference issues in invoice creation code by explicitly
typing event objects.


```

### Complete PR Example

```markdown
# Add proper typing for TransactionEvent types

## Summary

This PR adds comprehensive type safety to transaction events by replacing the generic `string` type with a `TransactionEventType` union type containing all 34 possible event types. This provides compile-time validation and autocomplete support throughout the codebase.

## Key Changes

- **Type Safety**: Created `TransactionEventType` union with 34 event types grouped by category
- **Compile-time Validation**: All transaction event types now type-checked at compile time
- **Developer Experience**: IDE autocomplete for event types throughout codebase
- **Bug Prevention**: Invalid event types caught during development, not production

## Technical Notes

- Union type includes: Stripe Invoice (15), Payment Intent (4), Checkout (2), Charge (2), Auto-Charge (3), Generic Payment (3), Job Pack (1) events
- All `createTransactionEvent()` calls now type-checked with no runtime changes
- Refactoring safety when renaming event types

## Breaking Changes

None - this is a non-breaking enhancement. All existing event type strings remain valid.

## Test Plan

- [x] TypeScript compilation passes
- [x] ESLint and Prettier pass
- [x] Type inference works correctly
- [x] No runtime behavior changes

---

## Tips

### Commit Messages

- **Keep it atomic**: One logical change per commit
- **Think about git log**: Will this make sense in 6 months?
- **Consider bisect**: Each commit should leave code in working state
- **Reference issues**: Use "Fixes #123" to auto-close issues

### Pull Requests

- **Keep it concise**: Focus on WHAT and WHY, not exhaustive file lists - GitHub shows the diff
- **Write for reviewers**: They don't have your context
- **Highlight risks**: Call out potential issues
- **Explain trade-offs**: Why this approach vs alternatives
- **Link everything**: Related PRs, issues, docs, Figma
- **Update as you go**: Add review feedback to description
- **Keep description updated**: If scope changes, update PR description
- **Use draft mode**: Create PRs as drafts, mark ready when all checks pass and ready for review
- **Include screenshots**: Add before/after screenshots for any UI or visual changes
### General

- **Be honest**: If something is hacky, say so
- **Be specific**: "Improved performance" → "Reduced query time by 40%"
- **Be consistent**: Follow project conventions exactly
- **Be helpful**: Make reviewer's job easy with clear descriptions
