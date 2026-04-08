---
name: managing-notes
description: Use when creating, renaming, or restructuring notes in the Obsidian vault at ~/Dropbox/Documents/notes. Routes to writing-* skills for format-specific work. Covers file naming, category prefixes, and vault organisation.
---

# Managing Notes

## Overview
Orchestrator for Marc's flat-file Obsidian vault at `~/Library/CloudStorage/Dropbox/Documents/notes/`. All organisation is through file naming — no subdirectories.

## When to Use
- Creating or renaming any note file
- Deciding which category a note belongs to
- Need to find or reference existing notes

## File Naming Convention

**Pattern:** `category-subcategory-snake_case_topic.md`

- `-` (hyphen) = hierarchy separator between levels
- `_` (underscore) = word separator within a single level

```
knowledgebase-cali.md
events-mothers_day_2026.md
recipe-korean-gochujan_chicken_thighs.md
travel-2026-europe.md
```

## Category Routing

| Prefix | Purpose | Delegate to |
|--------|---------|-------------|
| `recipe-` | Food recipes | **`writing-recipes`** skill |
| `knowledgebase-` | Structured reference for a person, place, or topic | — (format below) |
| `events-` | Event planning with date, checklist, logistics | — (format below) |
| `travel-` | Trip planning and itineraries | — |
| `todo-` | Task lists and logs | — |
| `list-` | General collections and reference lists | — |
| `work-` | Employment, projects, interviews | — |
| `goals-` | Personal and professional goals | — |
| `creativity-` | D&D, writing, creative projects | — |
| `thoughts-` | Essays, analysis, book/TV reviews | — |
| `housing-` | Home and household management | — |
| `exercise-` | Fitness routines and logs | — |
| `finance-` | Money, tax, accounts | — |
| `misc-` | Anything that doesn't fit above | — |

## General Formatting (all `.md` files)

### Frontmatter
All files use YAML frontmatter with `---` delimiters. Minimum fields:

```yaml
---
tags:
  - category
  - subcategory
---
```

Structured files add extra fields:

| Category | Additional fields |
|----------|-------------------|
| `knowledgebase-` | `type: knowledgebase`, `subject`, `updated: YYYY-MM-DD` |
| `events-` | `type: event`, `date: YYYY-MM-DD`, `subject`, `status` |
| `travel-` | `status` |
| `recipe-` | (see `writing-recipes` skill for full format) |

### Tags
Always use YAML array format in frontmatter. Tags are title-case, broad categories first then specific:

```yaml
tags:
  - Recipe
  - Cooking
  - Korean
  - Dinner
  - Chicken
```

**Not** inline backticks, comma-separated, or hashtags. One format everywhere.

### Headers
- `#` — file title (once, at top after frontmatter)
- `##` — major sections
- `###` — subsections (use sparingly)

### Lists & Checkboxes
- Unordered: `- item` (not `*` or `+`)
- Ordered: `1. item`
- Checkboxes: `- [ ]` unchecked, `- [x]` checked

### Links
- **Internal**: `[[wikilinks]]` (e.g. `[[travel-2026-europe]]`)
- **External**: `[text](url)` or raw URL if no label needed

### Dates
- **Frontmatter / structured fields**: ISO 8601 (`YYYY-MM-DD`)
- **Body content**: natural language (`Sunday, May 10, 2026`)
- **Recurring**: `**recurring: MMM DD**` in KB files

### Emphasis
- `**bold**` for key labels in content
- `<!-- comments -->` for hidden notes / placeholders
- Markdown tables with `|` pipes where tabular data helps

---

## Knowledge Base Files (`knowledgebase-*.md`)

Frontmatter: `type: knowledgebase`, `subject`, `updated: YYYY-MM-DD`

Standard sections (omit if empty): Identity, Key Dates, Preferences (Likes/Dislikes), Activities Wishlist, Restaurants & Places to Try, Traditions, Gift Ideas, Plans & Events, Completed, Notes.

Key dates format: `**recurring: MMM DD**` or `**YYYY-MM-DD**` — description.
Use `[[wikilinks]]` for cross-references. Update `updated` field on every edit.

## Event Files (`events-*.md`)

Frontmatter: `type: event`, `date: YYYY-MM-DD`, `subject`, `status: planning | confirmed | done`

Structure: schedule broken into time blocks, followed by a `## Prep Checklist` with deadlined action items.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hyphens for multi-word names | Underscores: `mothers_day` not `mothers-day` |
| Underscores between hierarchy levels | Hyphens: `recipe-korean` not `recipe_korean` |
| Creating subdirectories | Keep flat — use naming prefixes |
| Missing frontmatter on KB/event files | Always include `type`, `subject`, `updated`/`date` |
