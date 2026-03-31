---
name: query-logs-production
description: AUTO-INVOKE ONLY when the user explicitly mentions "production", "prod", "live", "vercel", or is investigating a bug reported by real users. Do NOT use this for checking errors during active local development — use query-logs-development instead. Queries Vercel production logs.
---

# Query Production Logs

Query Vercel production logs for investigation and bug hunting. Uses the project's structured `[LAYER:OPERATION]` logging format.

## How to Run

```bash
cd ~/work/legal-marketplace-2/apps/legal-marketplace && bun ~/.claude/scripts/query-logs-production.ts [flags]
```

Always run from the project directory so Vercel picks up the linked project.

**Prerequisites:** Vercel CLI should be installed globally (`npm i -g vercel`). The script falls back to `npx vercel` if not found, but this is slower. You must be authenticated (`vercel login`).

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--query` / `-q` | — | Full-text search across log messages |
| `--level` / `-l` | — | Filter by level: `error`, `warning`, `info`, `fatal` |
| `--status` / `-s` | — | Filter by HTTP status: `500`, `5xx`, `4xx` |
| `--source` | — | Filter by source: `serverless`, `edge-function`, `edge-middleware`, `static` |
| `--since` | `1h` | Time range start (ISO 8601 or relative: `1h`, `30m`, `2d`) |
| `--until` | — | Time range end |
| `--limit` / `-n` | `100` | Max entries to return |
| `--branch` / `-b` | `production` | Git branch to filter by (overrides jj/detached HEAD) |
| `--raw` | `false` | Output raw JSON lines (pipe to `jq`) |
| `--follow` / `-f` | `false` | Stream live logs |
| `--project` / `-p` | — | Override project (defaults to cwd's linked project) |

## Project Logging Conventions

The app uses structured logging with `[LAYER:OPERATION]` tags. Search for these to filter by area:

| Layer | Purpose | Example search |
|-------|---------|---------------|
| `DOMAIN` | Business logic | `--query "[DOMAIN:"` |
| `DATA` | Database queries | `--query "[DATA:"` |
| `INTEGRATION` | External API calls | `--query "[INTEGRATION:"` |
| `API` | API route handlers | `--query "[API:"` |
| `ACTION` | Next.js server actions | `--query "[ACTION:"` |
| `WEBHOOK` | Webhook handlers | `--query "[WEBHOOK:"` |

**Correlation fields** in logs: `correlationId`, `transactionId`, `jobPackId`, `firmId`, `userId`, `claimId`.

Logger source: `src/libs/logger/index.ts`

## Log Investigation Workflow

1. **Errors first** — Get the error landscape
   ```bash
   bun ~/.claude/scripts/query-logs-production.ts --level error --since 2h
   ```

2. **Narrow by time** — Focus on the incident window
   ```bash
   bun ~/.claude/scripts/query-logs-production.ts --level error --since "2025-01-15T10:00:00Z" --until "2025-01-15T11:00:00Z"
   ```

3. **Filter by layer** — Isolate the subsystem
   ```bash
   bun ~/.claude/scripts/query-logs-production.ts --query "[DATA:" --level error --since 1h
   ```

4. **Correlate by request** — Follow one request across layers
   ```bash
   bun ~/.claude/scripts/query-logs-production.ts --query "correlationId-value" --raw | jq '.'
   ```

5. **Check status codes** — Find failing endpoints
   ```bash
   bun ~/.claude/scripts/query-logs-production.ts --status 500 --since 2h
   ```

## Common Patterns

**All errors in the last hour:**
```bash
bun ~/.claude/scripts/query-logs-production.ts --level error
```

**500s on a specific path:**
```bash
bun ~/.claude/scripts/query-logs-production.ts --status 500 --query "/api/some-endpoint"
```

**Webhook failures:**
```bash
bun ~/.claude/scripts/query-logs-production.ts --query "[WEBHOOK:" --level error --since 4h
```

**Integration/external API errors:**
```bash
bun ~/.claude/scripts/query-logs-production.ts --query "[INTEGRATION:" --level error --since 2h
```

**Raw JSON for analysis:**
```bash
bun ~/.claude/scripts/query-logs-production.ts --level error --raw | jq '.message'
```

**Live tail (streaming):**
```bash
bun ~/.claude/scripts/query-logs-production.ts --follow --level error
```

## Retention Limits

| Plan | Retention |
|------|-----------|
| Hobby | 1 hour |
| Pro | 1 day |
| Enterprise | 3 days |

Query accordingly — don't set `--since 7d` on a Pro plan.

## Tips

- Always start with `--level error` to avoid noise
- Use `--raw` + `jq` for counting, grouping, or extracting specific fields
- The `[LAYER:OPERATION]` format is the fastest way to filter by subsystem
- Combine `--status 5xx` with `--query` for targeted endpoint debugging
- Use `--follow` sparingly — it streams for up to 5 minutes
- Check `src/libs/logger/index.ts` to understand what context fields are available
