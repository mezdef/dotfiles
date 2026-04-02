---
name: lint-conventions
description: >
  Fast convention check for legal-marketplace changes. Checks naming, layer
  architecture, and style rules that ESLint/TypeScript can't catch. Designed
  for small diffs (current changeset). Use after implementation or ad-hoc.
---

# Lint Conventions (legal-marketplace)

Invoke `/jj-diffs` to get the current changes, then review the diff against the rules below. Do NOT read any docs files — these rules are the complete reference.

Skip anything ESLint or TypeScript already catches (formatting, unused imports, type errors).

## Rules

### Layer violations

- **Actions must be thin:** withAuth + Zod validation + call domain + revalidatePath. No business logic.
- **DB/Drizzle queries only in data layer** (`src/data/`). Never in actions or domain.
- **Domain must not import** from actions, components, or Next.js (`next/`).

### Naming

| Layer | Files | Functions |
|-------|-------|-----------|
| Actions | `kebab-case.ts` | `verbSubjectAction` |
| Domain | `EntityUseCase.ts` | `verbSubject` (via namespace import) |
| Data | `EntityData.ts` | `verbSubject` (via namespace import) |
| Components (complex) | `PascalCase.tsx` | `PascalCase` |
| Components (primitives) | `kebab-case.tsx` | `PascalCase` |

- Types: `PascalCase`, no `I` prefix. Props: `ComponentNameProps`.
- Booleans: `is/has/can` prefix.
- DB tables: `snake_case` plural. Columns: `snake_case`.

### Style

- No `any` — use `unknown` with type guards.
- No nested ternaries.
- `const` only, no `let`.
- No `for`/`while` — use `map`/`filter`/`reduce`.
- `//` comments only, no `/* */` or `/** */`.
- Inline type imports: `import { type Foo } from "bar"`.

### Imports

- `~/` path alias for src imports.
- Namespace imports for domain/data: `import * as FirmsData from "~/data/..."`.
- Barrel imports from `@/components/ui`, `@actions`, `@utils`, `@libs`, `@types`, `@hooks`, `@db`.

## Output format

List issues only:
- `fix:` — must fix before committing
- `note:` — worth considering

If clean: "No convention issues found."

No summaries. No praise. No explanations unless needed for clarity.
