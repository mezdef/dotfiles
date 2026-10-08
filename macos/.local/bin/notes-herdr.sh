#!/bin/zsh
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Notes (Herdr)
# @raycast.mode silent
# Optional parameters:
# @raycast.icon 📝

# herdr port of notes.sh. Raycast runs with a minimal PATH, so resolve the
# binaries explicitly rather than relying on the interactive shell's PATH.
HERDR=${commands[herdr]:-/opt/homebrew/bin/herdr}
JQ=${commands[jq]:-/opt/homebrew/bin/jq}

NOTES_DIR="$HOME/Filesync/notes"
LABEL="Notes"

server_running() { "$HERDR" status server 2>/dev/null | grep -q '^status: running'; }

# Ensure the herdr server is up — workspace lookups need it, and attaching a
# client later reuses this same persistent session.
if ! server_running; then
  ("$HERDR" server >/dev/null 2>&1 &)
  for _ in {1..40}; do
    server_running && break
    sleep 0.1
  done
fi

# Ensure the Notes space exists
ws=$("$HERDR" workspace list 2>/dev/null |
  "$JQ" -r --arg l "$LABEL" 'first(.result.workspaces[] | select(.label == $l) | .workspace_id) // empty')

if [[ -z "$ws" ]]; then
  ws=$("$HERDR" workspace create --cwd "$NOTES_DIR" --label "$LABEL" --no-focus 2>/dev/null |
    "$JQ" -r '.result.workspace.workspace_id // empty')
fi

[[ -z "$ws" ]] && exit 1

# If nvim is not running in the space's focused pane, open it
pane=$("$HERDR" api snapshot 2>/dev/null | "$JQ" -r --arg w "$ws" '
  .result.snapshot as $s
  | ($s.workspaces[] | select(.workspace_id == $w) | .active_tab_id) as $t
  | [$s.panes[] | select(.tab_id == $t)]
  | (map(select(.focused)) + .)
  | first(.[].pane_id) // empty')

if [[ -n "$pane" ]]; then
  if ! "$HERDR" pane process-info --pane "$pane" 2>/dev/null |
    "$JQ" -e '[.result.process_info.foreground_processes[].name] | index("nvim")' >/dev/null; then
    "$HERDR" pane run "$pane" "nvim ." >/dev/null 2>&1
  fi
fi

# Focus the space server-side; any client that attaches lands on it
"$HERDR" workspace focus "$ws" >/dev/null 2>&1

# Bring up a client. A herdr client is any `herdr` process that is not the server.
client=$(pgrep -x herdr 2>/dev/null | while read -r pid; do
  ps -o command= -p "$pid" 2>/dev/null | grep -q ' server$' || echo "$pid"
done)

if [[ -n "$client" ]]; then
  # Client already attached — the focus call above already switched it
  open -a Ghostty
elif pgrep -q Ghostty; then
  # Ghostty running but nothing attached — focus and send the attach command
  open -a Ghostty
  sleep 0.3
  osascript -e 'tell application "System Events" to keystroke "herdr
" '
else
  # Ghostty not running — launch it attached
  open -a Ghostty --args -e herdr
fi
