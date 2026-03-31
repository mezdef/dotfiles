---
name: query-db-production
description: AUTO-INVOKE ONLY when the user explicitly mentions "production", "prod", "live", or is investigating a bug reported by real users. Do NOT use this for local development work. Provides safe read-only access to the production PostgreSQL read replica.
---

# Query Production Database

Safe read-only access to the production PostgreSQL read replica for investigation and bug hunting.

## Safety Rules (Non-Negotiable)

- **Read-only**: Only SELECT/WITH queries. The script enforces this at 4 layers.
- **Read replica only**: Uses `PROD_READ_REPLICA_URL`, never the primary.
- **LIMIT everything**: Auto-appended if missing. Never pull unbounded result sets.
- **No PII exposure**: Never log or output full names, emails, phone numbers, or addresses. Use aggregates, counts, or masked values.

## How to Run

```bash
cd ~/work/legal-marketplace-2/apps/legal-marketplace && bun ~/.claude/scripts/query-db-production.ts '<SQL>'
```

Always run from the project directory so `.env` and `node_modules` are available.

## Before Querying

1. Read `src/db/schema.ts` to understand table structures
2. Identify exact tables and columns needed
3. Use the naming conventions below

## Naming Conventions

| Layer | Tables | Columns | Example |
|-------|--------|---------|---------|
| TypeScript (Drizzle) | camelCase | camelCase | `firmPlans.firmsId` |
| SQL (Database) | PascalCase | snake_case | `"FirmPlans".firms_id` |

**Table format:** Always `public."PascalCase"` — e.g., `public."Firms"`, `public."JobPacks"`, `public."FirmPlans"`

## Bug Investigation Workflow

Follow this progression — start narrow, expand only as needed:

1. **Count** — Get the scale of the issue
   ```sql
   SELECT count(*) FROM public."Firms" WHERE status = 'active'
   ```

2. **Sample** — Look at a few affected rows (mask PII)
   ```sql
   SELECT id, status, created_at FROM public."Firms" WHERE status = 'active' LIMIT 10
   ```

3. **Narrow** — Filter to the specific case
   ```sql
   SELECT id, status, created_at FROM public."Firms" WHERE id = 'some-uuid'
   ```

4. **Join** — Follow relationships to find root cause
   ```sql
   SELECT f.id, fp.plan_type, fp.created_at
   FROM public."Firms" f
   JOIN public."FirmPlans" fp ON fp.firms_id = f.id
   WHERE f.id = 'some-uuid'
   LIMIT 50
   ```

5. **Summarize** — Aggregate for the report
   ```sql
   SELECT status, count(*) FROM public."Firms" GROUP BY status
   ```

## Common Patterns

**Check if a record exists:**
```sql
SELECT id, created_at FROM public."TableName" WHERE id = 'uuid' LIMIT 1
```

**Recent records:**
```sql
SELECT id, created_at FROM public."TableName" ORDER BY created_at DESC LIMIT 20
```

**Count by status/type:**
```sql
SELECT status, count(*) FROM public."TableName" GROUP BY status ORDER BY count DESC
```

## Pre-Query Checklist

Before running any query, verify:
- [ ] Query is SELECT/WITH only
- [ ] LIMIT clause is present
- [ ] No PII columns in output (or they are masked/aggregated)
- [ ] Table and column names use correct casing

## Red Flags

| Red Flag | Action |
|----------|--------|
| Query returns PII (emails, names, phones) | Mask or remove those columns |
| No LIMIT clause | Add one (script auto-adds LIMIT 100 as safety net) |
| Query touches 100k+ rows | Add WHERE clause to narrow scope |
| Query involves `SELECT *` | List specific columns instead |
| Timeout error | Add tighter filters or break into smaller queries |
