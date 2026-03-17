#!/bin/bash
# Hook: runs on agent finish (Stop event)
# - Runs lint --fix for any node project
# - Runs TypeScript check for legal-marketplace* projects

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
WORKDIR="${CWD:-$(pwd)}"

# Only run in node projects
if [ ! -f "$WORKDIR/package.json" ]; then
  exit 0
fi

cd "$WORKDIR" || exit 0

# Lint fix
bun lint --fix 2>&1

# TypeScript check only for legal-marketplace projects
if echo "$WORKDIR" | grep -qE "legal-marketplace"; then
  bun type 2>&1
fi

exit 0
