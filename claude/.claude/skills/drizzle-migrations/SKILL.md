---
name: drizzle-migrations
description: Use when making database schema changes, generating migrations, or resolving migration conflicts after merging upstream branches. Handles the full workflow from schema modification through conflict resolution using preserve-and-restore approach.
---

# Drizzle Migrations

## Overview

Drizzle auto-generates migrations from schema diffs, tracking state via snapshot files. Migration conflicts after upstream merges require a preserve-and-restore workflow to avoid breaking the snapshot chain.

## When to Use

- Adding or modifying tables, columns, indexes, enums, or constraints
- After merging master/upstream and seeing migration file conflicts (both added same file number)
- Multiple developers created same-numbered migrations (e.g., both created 0028)
- Need to add custom SQL for data backfills or complex migrations
- Migration numbering is misaligned with master branch
- Git shows conflicts in `migrations/meta/_journal.json`

## Quick Reference

| Task | Command | Notes |
|------|---------|-------|
| Generate migration | `bun db:generate` | Auto-generates from schema diff |
| Generate custom SQL | `bun db:generate --custom` | Opens SQL file for manual migration |
| Apply migrations | `bun db:migrate` | Runs prep-extensions first |
| Check migration status | `git diff master...HEAD -- migrations/` | See what changed |
| List migrations | `cat migrations/meta/_journal.json` | See numbered sequence |
| Detect conflicts | `git status` | Look for "both added" in migrations/ |

## Making Schema Changes Safely

Modify your schema in `src/db/schema.ts` following these patterns:

**Naming conventions:**
- Tables: PascalCase (e.g., `"FirmPlans"`, `"JobPacks"`)
- Columns: snake_case (e.g., `"firm_name"`, `"created_at"`)
- Variables: camelCase (e.g., `firmPlans`, `jobPacks`)

**Standard patterns:**
```typescript
// Use timestamps helper for created_at/updated_at
const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true, mode: "string" })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true, mode: "string" })
    .defaultNow()
    .notNull(),
} as const;

// Define enums before using in tables
export const firmPlanState = pgEnum("firm_plan_state", [
  "new",
  "freemium",
  "trial",
  "paid",
  "archived",
]);

// Standard table with UUID PK, timestamps, foreign keys, indexes
export const firmPlans = pgTable(
  "FirmPlans",
  {
    id: uuid().defaultRandom().primaryKey().notNull(),
    ...timestamps,
    firmsId: uuid("firms_id")
      .notNull()
      .references(() => firms.id, { onDelete: "cascade" }),
    state: firmPlanState("state").notNull(),
    planName: text("plan_name"),
    startDate: timestamp("start_date", { withTimezone: true, mode: "string" }).notNull(),
  },
  (table) => ({
    firmsIdStateIdx: index("FirmPlans_firms_id_state_idx").on(table.firmsId, table.state),
  })
);
```

## Generating Migrations

**Standard workflow:**
1. Modify schema in `src/db/schema.ts`
2. Run `bun db:generate`
3. **STOP: Verify migration integrity** (triple-check - DO NOT skip):
   - [ ] `migrations/XXXX_name.sql` exists with DDL statements
   - [ ] `migrations/meta/XXXX_snapshot.json` exists with matching number
   - [ ] `migrations/meta/_journal.json` has new entry with matching tag
   - [ ] Run `bun db:generate` again - it should generate NOTHING (confirms no drift)
4. **STOP: Prompt user for git operations** (NEVER auto-commit):
   ```bash
   # Tell user to run these commands:
   git add migrations/
   git status  # Review what's being staged
   git commit -m "Add migration: XXXX_description"
   ```
   Wait for user confirmation before proceeding

**For custom SQL (backfills, data migrations):**
1. Run `bun db:generate --custom`
2. Add your custom SQL using idempotent patterns:

```sql
-- Auto-generated DDL first
CREATE TABLE IF NOT EXISTS "FirmPlans" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  ...
);

-- Then add custom backfill in DO $$ block
DO $$
BEGIN
  INSERT INTO "FirmPlans" (firms_id, state, start_date)
  SELECT f.id, 'new'::"firm_plan_state", f.created_at
  FROM "Firms" f
  WHERE NOT EXISTS (
    SELECT 1 FROM "FirmPlans" fp WHERE fp.firms_id = f.id
  )
  ON CONFLICT DO NOTHING;
END $$;
```

## Resolving Migration Conflicts (Preserve-and-Restore)

**When this happens:** After merging upstream, git shows conflicts because two branches created the same migration number (e.g., your `0028_your_feature.sql` vs master's `0028_different_feature.sql`).

**The preserve-and-restore workflow:**

### Step 1: Note Migration Name and Save Custom SQL

First, note your original migration name to preserve it:

```bash
# Note the descriptive name (e.g., 0028_man_under_water.sql)
# You'll use this name with the new number later (0029_man_under_water.sql)
ls migrations/0028_*.sql
```

Check if your migration has custom SQL beyond auto-generated schema DDL:

```bash
# Look for custom DO $$ blocks, backfills, data migrations
grep -A 20 "DO \$\$" migrations/0028_your_migration.sql

# If found, save to temporary file
grep -A 50 "DO \$\$" migrations/0028_your_migration.sql > /tmp/custom_sql_backup.txt
```

### Step 2: Delete Your Conflicting Migration Files

```bash
# Remove your migration SQL file
rm migrations/0028_your_migration.sql

# Remove your snapshot file
rm migrations/meta/0028_snapshot.json
```

### Step 3: Edit Journal to Remove Your Entry

Open `migrations/meta/_journal.json` and remove your conflicting entry:

```json
{
  "entries": [
    ...
    {
      "idx": 27,
      "version": "7",
      "when": 1234567890,
      "tag": "0027_previous_migration",
      ...
    },
    // DELETE THIS ENTRY (your 0028):
    {
      "idx": 28,
      "version": "7",
      "when": 1767593590704,
      "tag": "0028_your_migration",
      ...
    }
    // Keep master's entries (they'll be added during merge)
  ]
}
```

Save the file after removing ONLY your conflicting entry.

### Step 4: Merge Upstream Changes

**STOP: Prompt user to merge** (do not run git operations yourself):

Tell user to run:
```bash
# Complete your merge/rebase
git pull origin master
# OR
git rebase master
```

Wait for user confirmation that merge is complete before proceeding to Step 5.

### Step 5: Regenerate Your Migration with Preserved Name

```bash
# This creates the next available number (0029, 0030, etc.) with a random name
bun db:generate

# Preserve your original descriptive name
# If original was 0028_man_under_water.sql, rename to 0029_man_under_water.sql
mv migrations/0029_random_generated_name.sql migrations/0029_man_under_water.sql
mv migrations/meta/0029_snapshot.json migrations/meta/0029_snapshot.json  # Snapshot keeps same number
```

Update the journal entry to match your preserved name:

```bash
# Edit migrations/meta/_journal.json
# Find the newest entry (idx: 29) and update the "tag" field:
# Change: "tag": "0029_random_generated_name"
# To: "tag": "0029_man_under_water"
```

**STOP: Verify migration integrity** (triple-check - DO NOT skip):
- [ ] `migrations/0029_man_under_water.sql` exists
- [ ] `migrations/meta/0029_snapshot.json` exists with matching number
- [ ] `migrations/meta/_journal.json` has entry with tag "0029_man_under_water"
- [ ] Run `bun db:generate` again - should generate NOTHING (confirms no drift)

**Why preserve the name:** The descriptive name helps track what changes are in the migration. Using the same name (with updated number) maintains continuity and makes it clear this is the same feature that was renumbered due to conflicts.

### Step 6: Restore Custom SQL (if you saved any in Step 1)

If you had custom backfills or data migrations:

1. Open the newly generated migration file (e.g., `migrations/0029_new_name.sql`)
2. Add your custom SQL from the backup at the END of the file:

```sql
-- Auto-generated DDL (already in file)
CREATE TABLE IF NOT EXISTS "YourTable" (...);
CREATE INDEX IF NOT EXISTS ...;

-- Manually restored custom SQL (add this)
DO $$
BEGIN
  -- Your backfill logic here
  INSERT INTO "YourTable" ...
END $$;
```

### Step 7: Final Verification and Commit

**STOP: Triple-check everything** (DO NOT skip):
- [ ] All three files exist: SQL, snapshot, journal entry
- [ ] Journal tag matches SQL filename
- [ ] Run `bun db:generate` - should generate NOTHING
- [ ] Custom SQL (if any) is present in migration file

**STOP: Prompt user for git operations** (NEVER auto-commit):

Tell user to run:
```bash
git add migrations/
git status  # Review what's being staged
git commit -m "Resolve migration conflict: renumber to 0029_man_under_water"
```

Wait for user confirmation before proceeding.

### Why This Works

- **Snapshot chain**: Drizzle tracks schema state in snapshot files. Deleting your migration resets your branch's state to before the conflict.
- **Canonical numbering**: After merge, master's 0028 is the canonical version. Your changes regenerate as 0029+.
- **Manual SQL preservation**: Drizzle can't auto-generate custom logic (backfills, data migrations). You must manually restore these from backup.

## Red Flags - STOP Immediately

These thoughts mean you're about to corrupt the migration chain:

| Thought | Reality |
|---------|---------|
| "I'll skip verification, user is waiting" | 30 seconds prevents hours of debugging schema corruption |
| "The tool worked, files must be fine" | Tools generate files, not validate logic. Verify ALWAYS |
| "I'll commit this for the user" | Migrations require human review. NEVER auto-commit |
| "I'll just move files around manually" | Snapshots are cryptographically linked. Regenerate, don't rename |
| "I'll check if it breaks later" | Schema corruption is undetectable until production fails |
| "One file exists, others must too" | Journal/snapshot/SQL can be out of sync. Check ALL three |

**All of these mean: STOP. Follow the verification checklist.**

## Common Mistakes

**DO NOT do any of these:**

| Mistake | Why It Breaks | Instead |
|---------|---------------|---------|
| Manually renumber migration to 0029 | Snapshot IDs won't match the SQL file. Drizzle can't track state. | Delete and regenerate via `bun db:generate` |
| Merge migration SQL files | Each snapshot.json is tied to specific SQL content. Merging corrupts the link. | Follow preserve-and-restore workflow |
| Edit snapshot.json manually | Snapshots are generated artifacts. Manual edits create undetectable corruption. | Never touch snapshot files |
| Forget to remove journal entry | Journal is append-only. Stale entries cause numbering conflicts. | Always manually remove your conflicting entry |
| Delete migration without saving custom SQL | Data migration logic is permanently lost. Can't be auto-regenerated. | ALWAYS grep for "DO $$" and save first |
| Run `bun db:generate` before cleanup | Drizzle sees conflict state and creates malformed migration. | Clean up conflicts completely before regenerating |

**Rationalization Counters:**

- **"I'll just renumber manually"** → NEVER manually renumber. Snapshot IDs won't match. The snapshot chain will be permanently broken.
- **"I can merge the SQL files"** → Each snapshot.json is cryptographically tied to specific SQL. Merging SQL breaks this link irreparably.
- **"The journal will auto-update"** → Journal is append-only by design. You MUST manually remove your conflicting entry. It will not auto-fix.
- **"I'll remember the custom SQL"** → ALWAYS save first. Even simple backfills have edge cases, ON CONFLICT clauses, and WHERE conditions you'll forget.
- **"I can edit the snapshot to fix conflicts"** → Snapshots are generated artifacts with internal consistency checks. Manual edits create undetectable corruption that breaks migrations silently.
- **"bun db:generate is reliable, verification adds no value"** → Tools can't detect logical errors (duplicate migrations, schema drift). Verification catches what automated tools miss.
- **"User wants to move on, I'll skip the checks"** → Skipping verification creates permanent schema corruption. 30 seconds of checking prevents hours of debugging.
- **"If one file exists, the others almost certainly do"** → WRONG. Journal can be out of sync, snapshot can be stale, SQL can be empty. Verify ALL three files ALWAYS.
- **"I'll just commit these changes myself"** → NEVER auto-commit migrations. User must review staged files. Schema changes require human verification before commit.

## Keywords

drizzle, migration, conflict, journal, snapshot, merge, upstream, schema, generate, backfill, custom SQL, enum, foreign key, preserve-and-restore, both added, git conflict, DO $$, data migration, idempotent, verification, triple-check, drift, schema drift, auto-commit, prompt user, matching files, snapshot chain corruption
