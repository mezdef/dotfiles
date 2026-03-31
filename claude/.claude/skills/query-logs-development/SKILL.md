---
name: query-logs-development
description: AUTO-INVOKE when verifying changes work, checking for errors after edits, or debugging during active development. This is the DEFAULT log skill when you are actively editing code in the monorepo — use this unless the user explicitly says "production", "prod", "live", or "vercel". Queries local dev log files in .logs/.
---

# Query Development Logs

Query local development log files for debugging and verifying changes. Logs are written to `~/work/legal-marketplace-2/.logs/` by service wrapper scripts.

## How to Run

```bash
bun ~/.claude/scripts/query-logs-development.ts [flags]
```

**Prerequisite:** Services must be started via `~/.claude/scripts/dev-with-logging.sh <service>` to capture logs. Without this, logs go to terminal stdout only and aren't queryable.

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--service` / `-s` | all | Which log: `marketplace`, `leap-leads`, `inngest`, `stripe`, `drizzle`, or `all` |
| `--query` / `-q` | — | Text/regex search (case-insensitive) |
| `--level` / `-l` | — | Filter by level: `error`, `warn`, `info`, `debug` |
| `--layer` | — | Filter by layer: `DOMAIN`, `DATA`, `INTEGRATION`, `API`, `ACTION`, `WEBHOOK` |
| `--last` / `-n` | `50` | Show last N matching lines |
| `--errors` / `-e` | `false` | Shorthand for errors + warnings only |
| `--raw` | `false` | Output raw lines (no color formatting) |

## Services and Log Files

| Service | Log file | Command |
|---------|----------|---------|
| marketplace | `.logs/marketplace.log` | `next dev --turbopack` |
| leap-leads | `.logs/leap-leads.log` | `next dev` |
| inngest | `.logs/inngest.log` | `inngest-cli dev` |
| stripe | `.logs/stripe.log` | `stripe listen --forward-to` |
| drizzle | `.logs/drizzle.log` | `drizzle-kit studio` |

## Feedback Loop Workflow

After making changes to server-side code:

1. **Make changes** to server actions, API routes, or background jobs
2. **Wait for compilation** — Next.js turbopack recompiles on save
3. **Trigger the code path** — visit the page, call the API, or trigger the job
4. **Check logs immediately:**
   ```bash
   bun ~/.claude/scripts/query-logs-development.ts -s marketplace --errors
   bun ~/.claude/scripts/query-logs-development.ts -s marketplace --last 20
   ```
5. **Iterate** if errors found

## Project Logging Conventions

The app uses structured logging with `[LAYER:OPERATION]` tags:

| Layer | Purpose | Example search |
|-------|---------|---------------|
| `DOMAIN` | Business logic | `--layer DOMAIN` |
| `DATA` | Database queries | `--layer DATA` |
| `INTEGRATION` | External API calls | `--layer INTEGRATION` |
| `API` | API route handlers | `--layer API` |
| `ACTION` | Next.js server actions | `--layer ACTION` |
| `WEBHOOK` | Webhook handlers | `--layer WEBHOOK` |

Logger source: `src/libs/logger/index.ts`

## Common Patterns

**All errors across services:**
```bash
bun ~/.claude/scripts/query-logs-development.ts --errors
```

**Recent marketplace output:**
```bash
bun ~/.claude/scripts/query-logs-development.ts -s marketplace --last 20
```

**Filter by layer:**
```bash
bun ~/.claude/scripts/query-logs-development.ts -s marketplace --layer ACTION
```

**Search for a term:**
```bash
bun ~/.claude/scripts/query-logs-development.ts --query "firmId" -s marketplace
```

**Inngest job failures:**
```bash
bun ~/.claude/scripts/query-logs-development.ts -s inngest --errors
```

**Compilation errors:**
```bash
bun ~/.claude/scripts/query-logs-development.ts -s marketplace --query "error|failed to compile"
```

## Tips

- After editing server actions or API routes, trigger them and immediately check logs
- Use `--errors` first to cut through noise
- The `[LAYER:OPERATION]` format lets you isolate subsystems quickly
- Compilation errors show up in marketplace/leap-leads logs
- Inngest job failures appear in both inngest and marketplace logs
- Stripe webhook delivery status appears in stripe logs
