#!/bin/bash
# Hook: PostToolUse — remind about plan lifecycle after plan-related tool uses
# Triggers:
#   - ExitPlanMode: plan just written, remind to rename + set status
#   - Write/Edit on plan files: remind about lifecycle management

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL_NAME" in
    ExitPlanMode)
        cat <<'MSG'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN LIFECYCLE REMINDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan mode just exited. Before continuing:
  1. Rename if needed: YYYY-MM-DD-feature-name.md
  2. Move to correct status: plan-move.sh <file> todo

Use /managing-plans for lifecycle operations.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
        ;;
    Write|Edit)
        TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

        if echo "$FILE_PATH" | grep -q '\.claude/plans/'; then
            cat <<'MSG'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN FILE UPDATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A plan file was modified. Consider:
  - Update progress markers (✅/🔴)
  - Move status if work is complete: plan-move.sh <file> done

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
        fi
        ;;
esac

exit 0
