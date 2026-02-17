#!/bin/bash
set -e
cat | bun run "$HOME/.claude/hooks/skill-activation-prompt.ts"
