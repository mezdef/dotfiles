---
name: write-sql-script
description: AUTO-INVOKE when user asks to write SQL scripts, create database queries, fix data, update records, or run ad-hoc database operations. Produces a single script with verification and execution sections.
---

# Write SQL Script

## Overview

Write SQL scripts for the legal-marketplace database with proper naming conventions and safety patterns. Produces a single script with verification queries followed by execution (mutation) wrapped in a transaction.

## Before Writing Scripts

1. Read the schema at `src/db/schema.ts` to understand table structures and relationships
2. Identify the exact tables and columns needed
3. Map TypeScript names to SQL names using the conventions below

## Naming Conventions

| Layer | Tables | Columns | Example |
|-------|--------|---------|---------|
| TypeScript (Drizzle) | camelCase | camelCase | `firmPlans.firmsId` |
| SQL (Database) | PascalCase | snake_case | `"FirmPlans".firms_id` |

**Table Reference Format:** Always use fully-qualified PostgreSQL identifiers:
- Correct: `public."FirmPlans"`, `public."Firms"`, `public."JobPacks"`
- Wrong: `FirmPlans`, `firm_plans`, `"FirmPlans"`

**Common mappings:**
| TypeScript | SQL Table | SQL Column |
|------------|-----------|------------|
| `firms` | `public."Firms"` | - |
| `firmPlans` | `public."FirmPlans"` | - |
| `jobPacks` | `public."JobPacks"` | - |
| `firmsId` | - | `firms_id` |
| `createdAt` | - | `created_at` |
| `firmName` | - | `firm_name` |

## Script Structure

Produce ONE script with two sections:

1. **VERIFICATION SECTION** - Read-only queries to preview affected data (run first, outside transaction)
2. **EXECUTION SECTION** - Mutation wrapped in BEGIN/ROLLBACK transaction

```sql
-- =============================================================================
-- SQL SCRIPT: {Brief description}
-- =============================================================================
-- Purpose: {Detailed explanation of what this script does and why}
-- Date: {YYYY-MM-DD}
-- Author: Claude
--
-- HOW TO USE:
-- 1. Run the VERIFICATION SECTION first (outside transaction)
-- 2. Review the output - if unexpected, STOP and investigate
-- 3. Run the EXECUTION SECTION (uses ROLLBACK by default)
-- 4. Review results, then change ROLLBACK to COMMIT and re-run
-- =============================================================================


-- #############################################################################
-- VERIFICATION SECTION (run first, outside transaction)
-- #############################################################################

-- -----------------------------------------------------------------------------
-- VERIFY 1: Count total records that match our criteria
-- This tells us the scope of the change
-- -----------------------------------------------------------------------------
SELECT COUNT(*) as total_records_affected
FROM public."TableName"
WHERE {conditions};

-- -----------------------------------------------------------------------------
-- VERIFY 2: Preview sample of affected records
-- Shows actual data that will be modified, including current values
-- -----------------------------------------------------------------------------
SELECT
    id,
    column1,          -- Current value that will change
    column2,          -- Related field for context
    created_at,       -- When record was created
    updated_at        -- Last modification time
FROM public."TableName"
WHERE {conditions}
ORDER BY created_at DESC
LIMIT 20;

-- -----------------------------------------------------------------------------
-- VERIFY 3: Additional context queries (if needed)
-- Related data that helps understand the impact
-- -----------------------------------------------------------------------------
-- Add any additional verification queries here


-- #############################################################################
-- EXECUTION SECTION (run after verification passes)
-- #############################################################################

BEGIN;

-- -----------------------------------------------------------------------------
-- EXECUTE 1: {Description of the main operation}
-- {Explain WHY we're making this change}
-- -----------------------------------------------------------------------------
UPDATE public."TableName"
SET
    column_name = 'new_value',     -- {Explain what this change does}
    updated_at = NOW()             -- Always update the timestamp
WHERE {conditions};

-- -----------------------------------------------------------------------------
-- EXECUTE 2: Verify the changes were applied correctly
-- This SELECT should show the updated values
-- -----------------------------------------------------------------------------
SELECT
    id,
    column_name,      -- Should now show 'new_value'
    updated_at        -- Should show current timestamp
FROM public."TableName"
WHERE {conditions_for_verification}
LIMIT 10;

-- -----------------------------------------------------------------------------
-- EXECUTE 3: Final record count
-- Confirm the expected number of rows were affected
-- -----------------------------------------------------------------------------
SELECT COUNT(*) as rows_modified
FROM public."TableName"
WHERE {conditions_for_verification};

-- =============================================================================
-- COMMIT OR ROLLBACK
-- =============================================================================
-- DEFAULT: ROLLBACK - changes are NOT saved
-- Change to COMMIT only after verifying the results above are correct
-- =============================================================================
ROLLBACK;
-- COMMIT;
```

## Commenting Standards

Every script MUST include:

1. **Header block** with:
   - Brief description
   - Purpose explanation
   - Date and author
   - Instructions for use

2. **Section markers** (`-- ###...`) separating VERIFICATION and EXECUTION sections

3. **Step dividers** (`-- ---...`) between logical steps

4. **Inline comments** explaining:
   - WHY each query/operation is performed
   - WHAT each column represents in context
   - Any non-obvious logic or conditions

5. **Step labels** (VERIFY 1, EXECUTE 1, etc.) for clarity

## Script Patterns

### UPDATE Pattern
```sql
-- Update firm names for a specific set of firms
-- Reason: {explain the business need}
UPDATE public."Firms"
SET
    firm_name = 'New Name',   -- New display name
    updated_at = NOW()        -- Track modification time
WHERE id = 'uuid-here';
```

### DELETE Pattern
```sql
-- Remove pending job invitations that are stale
-- Reason: These invitations expired and should be cleaned up
DELETE FROM public."JobInvitations"
WHERE jobs_id = 'uuid-here'
  AND status = 'pending'      -- Only remove pending, not accepted/declined
  AND created_at < NOW() - INTERVAL '30 days';  -- Only stale ones
```

### INSERT Pattern
```sql
-- Create a new trial plan for a firm
-- Reason: Firm requested upgrade from freemium to trial
INSERT INTO public."FirmPlans" (
    id,                       -- UUID primary key
    firms_id,                 -- Foreign key to Firms table
    state,                    -- Plan state enum
    start_date,               -- When trial begins
    created_at,               -- Record creation timestamp
    updated_at                -- Record update timestamp
)
VALUES (
    gen_random_uuid(),        -- Auto-generate UUID
    'firm-uuid',              -- Target firm ID
    'trial',                  -- Trial plan state
    NOW(),                    -- Start immediately
    NOW(),                    -- Created now
    NOW()                     -- Updated now
);
```

### JOIN Pattern
```sql
-- Get firm names with their current plan states
-- Used to audit which firms are on which plans
SELECT
    f.firm_name,              -- Firm's display name
    fp.state,                 -- Current plan state
    fp.start_date,            -- When plan started
    fp.end_date               -- When plan ends (NULL if active)
FROM public."Firms" f
JOIN public."FirmPlans" fp ON fp.firms_id = f.id
WHERE fp.state = 'active'     -- Only current active plans
  AND fp.end_date IS NULL;    -- Not archived
```

## Output Requirements

1. **Save script** to `~/work/legal-marketplace/apps/legal-marketplace/scripts/`
2. File naming: `YYYY-MM-DD-{task-description}.sql`
   - Example: `2026-02-02-fix-firm-plan-states.sql`

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll skip the verification section" | NEVER skip. Verification prevents disasters. |
| "I can use camelCase in SQL" | Wrong. SQL uses snake_case for columns. |
| "Table name without quotes is fine" | Wrong. Must use `public."PascalCase"` format. |
| "COMMIT by default is fine" | NEVER. Always ROLLBACK by default, COMMIT commented. |
| "I know the schema" | Always read `src/db/schema.ts` first. |
| "Comments are unnecessary" | NEVER. Every script must be well-documented. |

## Checklist

Before delivering script:
- [ ] Read `src/db/schema.ts` to verify table/column names
- [ ] Tables use `public."PascalCase"` format
- [ ] Columns use snake_case
- [ ] Header block with purpose, date, instructions
- [ ] VERIFICATION section with read-only queries
- [ ] EXECUTION section with BEGIN/ROLLBACK pattern
- [ ] Section markers and step dividers between logical steps
- [ ] All operations have inline comments explaining WHY
- [ ] Script saved to scripts/ folder
