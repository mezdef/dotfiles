---
name: browser-dev
description: AUTO-INVOKE when verifying UI changes, debugging client-side errors, checking console/network issues, or when server logs show no errors but something seems wrong. Uses Playwright MCP for browser automation. NOT for pure server-side changes (use query-logs-development instead).
---

# Browser Dev — Playwright MCP

Use Playwright MCP tools to verify client-side behavior during local development. **Be token-conscious** — browser operations vary wildly in cost.

## Token Cost Tiers

| Tier | Operations | ~Tokens | Rule |
|------|-----------|---------|------|
| **Cheap** | navigate, click, fill, hover, select, get page title/URL | <100 | Use freely |
| **Medium** | console logs (filtered), execute targeted JS, check specific element | 100-500 | Use when needed |
| **Expensive** | screenshot, full accessibility snapshot, all network requests, full console dump | 500-2000+ | **Confirm with user first** — explain what you'll capture and why |

## Before Using Expensive Operations

You MUST confirm with the user before:

- **Screenshots:** "Taking a screenshot will use ~1000-2000 tokens. Want me to capture the page?"
- **Full accessibility snapshots:** "A full page snapshot will use ~500-2000 tokens depending on complexity. Proceed?"
- **All network requests:** "Network dump could be large. Want me to filter to errors only instead?"
- **Full console dump:** "Full console output could be verbose. Want me to filter to errors/warnings only?"

## When to Use

- After making UI/component changes — verify they render
- When debugging client-side behavior (React errors, hydration issues)
- When server logs show no errors but the feature isn't working
- When verifying form flows, navigation, or interactive behavior

## When NOT to Use

- Pure server-side changes → use `query-logs-development` instead
- Checking if code compiles → check dev logs
- API-only changes with no UI impact
- Anything you can verify with unit tests

## Token-Conscious Workflow

Always escalate from cheap to expensive:

1. **Check dev logs first** (free — already captured in .logs/)
2. **Navigate + check console errors** (cheap — catches most client issues)
3. **Execute targeted JS** to check specific element state (medium — avoids full snapshot)
4. **Screenshot only if needed** for visual/layout issues (expensive — confirm first)

## Prefer Targeted Over Broad

| Instead of... | Do this... |
|---------------|-----------|
| Full console dump | Console logs filtered to "error" |
| Full accessibility snapshot | Execute JS: `document.querySelector('.target')?.textContent` |
| All network requests | Filter to failed requests or specific endpoints |
| Screenshot of full page | Screenshot of specific element (if supported) |

## Common Efficient Patterns

**"Did my change break anything?"** (cheap)
→ Navigate to the page + check console for errors

**"Does the form work?"** (cheap)
→ Navigate + fill fields + submit + check console for errors

**"Does it look right?"** (expensive — confirm first)
→ Navigate + screenshot

**"Why is the API call failing?"** (medium)
→ Navigate + trigger the action + check network errors

**"Is the component rendering?"** (medium)
→ Navigate + execute JS to check if element exists and has expected content

## Prerequisites

- Dev server running (marketplace on localhost:3000)
- Playwright MCP server configured (already done — `~/.claude.json`)
- Browser runs headless by default

## Tips

- Console errors after navigation are the highest-signal, lowest-cost check
- If you need to verify text content, use JS execution instead of screenshots
- For form testing, the fill + submit + console check pattern catches most issues without screenshots
- Hydration errors show up in console — no screenshot needed
