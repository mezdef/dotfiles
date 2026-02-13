---
name: quick-fix
description: Use for trivial code changes that don't require planning or review. Examples - typos, formatting, single-line fixes, renaming variables, adding missing imports, fixing obvious bugs. NEVER use for logic changes, new features, or multi-file refactors.
---

# Quick Fix

Lightweight skill for trivial code changes that bypass normal workflow overhead.

## When to Use

**USE this skill for:**
- Fixing typos in strings, comments, or variable names
- Adding missing imports
- Formatting fixes (spacing, indentation, line breaks)
- Renaming a single variable consistently
- Fixing obvious syntax errors
- Updating a single constant value
- Adding a missing semicolon, comma, or brace
- Correcting an obvious type annotation
- Changing a hardcoded value to a constant reference

**NEVER use for:**
- Any logic changes (if/else, loops, calculations)
- New features or functionality
- Database schema changes
- API endpoint modifications
- Multi-file refactors (>2 files)
- Changes requiring tests
- Architectural decisions
- Security-sensitive code
- Anything requiring `/code-implement`

## Validation Rules

Before making changes, verify:

1. **Scope:** ≤5 lines changed total across all files
2. **Impact:** Zero behavior change (pure cosmetic or obvious fix)
3. **Files:** ≤2 files modified
4. **Testing:** No tests need updating

If ANY rule is violated, STOP and use `/code-implement` instead.

## Workflow

1. Quickly verify the change location with Read
2. Make the minimal edit
3. Confirm the fix
4. Done - no review needed

## Examples

### ✅ Good Quick Fixes
```typescript
// Typo fix
- console.log('Sucessfully saved')
+ console.log('Successfully saved')

// Missing import
+ import { type User } from '~/types/user'

// Rename variable (single scope)
- const usr = getUser()
- return usr.name
+ const user = getUser()
+ return user.name

// Fix obvious type
- const count: string = 5
+ const count: number = 5
```

### ❌ NOT Quick Fixes (use /code-implement)
```typescript
// Logic change - requires review
- if (user.role === 'admin') {
+ if (user.role === 'admin' || user.role === 'superadmin') {

// New functionality - requires planning
+ export function calculateDiscount(price: number) {
+   return price * 0.1
+ }

// Database change - requires migration
- createdAt: timestamp('created_at')
+ createdAt: timestamp('created_at').notNull()

// Multi-file refactor - requires review
// Moving code between files, restructuring
```

## Communication

- Keep responses brief (1-2 sentences)
- No need to explain obvious changes
- Just confirm what was fixed

## Remember

Quick Fix is a privilege, not a right. When in doubt, use the full workflow.

**Token budget:** Aim for <500 tokens total (skill invocation + changes + response)
