---
name: jj-management
description: Use when splitting, squashing, moving changes between jj revisions, grouping changes into logical changesets, or describing commits in a jj repository.
disable-model-invocation: true
---

# jj Changeset Management

**Announce at start:** "I'm using the jj-management skill to manage changesets."

## Critical Rules

- **Never use `--interactive`/`-i`** — opens a diff editor Claude cannot operate.
- **Never use `jj split`** — always opens a diff editor, even with file paths. Use `jj new` + `jj squash --from --into <files>` instead (see Splitting section).
- **Never use git commands** for VCS operations — use jj equivalents.
- **Never push or create PRs** — user handles all remote operations.
- **Bookmarks only with a known Linear ticket** — format: `feat/<ticket-id>-<short-name>`.
- **Clear source descriptions before emptying** — if a `jj squash` will empty a revision that has a description, first run `jj describe -r <source> -m ""` to avoid an interactive description merge prompt.

## Moving Changes Between Changesets

The most error-prone operation. Always be explicit with `--from` and `--into`.

| Command | What it does |
|---------|-------------|
| `jj squash <files>` | Move specific files from `@` into its parent |
| `jj squash` | Move ALL changes from `@` into its parent (empties `@`) |
| `jj squash --from <rev> --into <rev> <files>` | Move specific files between arbitrary revisions |
| `jj squash --from <rev> --into <rev>` | Move ALL changes between arbitrary revisions |

### Gotchas

- **Source is abandoned if emptied** — unless you pass `--keep-emptied`
- **Defaults**: `--from` defaults to `@`, `--into` defaults to `@` — always be explicit to avoid surprises
- **Description merge**: If both source and destination have descriptions and source gets emptied, jj opens an interactive editor to merge descriptions (which Claude can't answer). **Fix:** clear the source description first with `jj describe -r <source> -m ""`, then squash. Alternatively use `--keep-emptied`.

## Splitting a Changeset

**Do NOT use `jj split`** — it always opens a diff editor. Instead, use `jj new` + `jj squash`:

**Step-by-step:**

1. Survey: `jj diff --stat -r <rev>` to see all files in the changeset
2. Group files by logical concern
3. If source has a description and will be emptied: `jj describe -r <rev> -m ""`
4. Create target: `jj new <parent-of-rev> -m "wip - <description>"`
5. Move files: `jj squash --from <rev> --into @ <files...>`
6. Repeat steps 4-5 for each group
7. Verify: `jj log -r 'trunk()..@'`

## Grouping Workflow

Full recipe for organizing mixed changes into logical changesets:

**Phase 1 — Survey:**
```bash
jj diff --stat
```

**Phase 2 — Plan groups:** Identify logical groupings (by component, concern, or feature). List them before acting.

**Phase 3 — Prep source:** If the source changeset has a description and will be fully emptied:
```bash
jj describe -r <source> -m ""
```

**Phase 4 — Split into groups:** For each group:
```bash
jj new <parent> -m "wip - <description>"
jj squash --from <source> --into @ <files...>
```
Each `jj new` creates a new changeset with the description already set, then `jj squash` moves the relevant files into it.

**Phase 5 — Verify:**
```bash
jj log -r 'trunk()..@'
```
Confirm each changeset has the right files and description.

## Describing Conventions

| Context | Format | Example |
|---------|--------|---------|
| During development | `wip - <description>` | `wip - Add per-finger timing config` |
| Dotfiles final | `Component - Action description` | `Kanata - Add per-finger timing` |
| Work repos final | `INITIALS - Action description` | `MD - Add batch insert for events` |

**Rules:**
- Imperative mood: "Add" not "Added"
- Specific: "Add email validation" not "Update form"
- Under 72 characters

## Bookmarks

Only create when working on a known Linear ticket.

| Command | Purpose |
|---------|---------|
| `jj bookmark create feat/<name> -r <rev>` | Create bookmark at revision |
| `jj bookmark move feat/<name> -r <rev>` | Move bookmark to new revision |
| `jj bookmark delete <name>` | Remove bookmark |
| `jj bookmark list` | List all bookmarks |

## Quick Reference

| Command | Purpose |
|---------|---------|
| `jj new` | Create empty child of `@` |
| `jj new <rev>` | Create empty child of specific revision |
| `jj commit -m "..."` | Describe `@` + create new empty child (= `jj describe` + `jj new`) |
| `jj describe -m "..."` | Set description on `@` |
| `jj describe -r <rev> -m "..."` | Set description on specific revision |
| `jj abandon` | Discard working copy changeset |
| `jj abandon <rev>` | Discard specific changeset |
| `jj edit <rev>` | Make a historical revision the working copy |
| `jj rebase -r <rev> -d <dest>` | Move a single changeset |
| `jj rebase -s <rev> -d <dest>` | Move changeset and all descendants |

## Common Mistakes

| Mistake | What happens | Fix |
|---------|-------------|-----|
| `jj split` (any form) | Always opens diff editor Claude can't use | Use `jj new` + `jj squash --from --into <files>` |
| `jj squash` without checking what's in `@` | May squash more than intended | `jj diff --stat` first |
| Forgetting `--from`/`--into` on squash | Defaults to `@` which may not be what you want | Always be explicit |
| Squashing into revision with description | Interactive description merge prompt | Use `--keep-emptied` or describe destination first |
| Using `git commit`, `git add` | Bypasses jj, causes state confusion | Use `jj commit`, `jj squash` |
| Creating bookmark without Linear ticket | Unnecessary bookmark clutter | Only create for tracked work |
| Not verifying after split/squash | Changes may be in wrong changeset | Always `jj log` + `jj diff --stat -r <rev>` after |
