#!/bin/zsh
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Notes
# @raycast.mode silent
# Optional parameters:
# @raycast.icon 📝

# Ensure Notes tmux session exists
tmux has-session -t Notes 2>/dev/null || tmux new-session -d -s Notes

# If nvim is not running in the Notes session, open it
if ! tmux list-panes -t Notes -F '#{pane_current_command}' 2>/dev/null | grep -q nvim; then
  tmux send-keys -t Notes "nvim ." Enter
fi

if tmux list-clients -F '#{client_name}' 2>/dev/null | grep -q .; then
  # tmux client exists — focus Ghostty and switch client to Notes
  open -a Ghostty
  client=$(tmux list-clients -F '#{client_name}' | head -1)
  tmux switch-client -c "$client" -t Notes
elif pgrep -q Ghostty; then
  # Ghostty running but no tmux client — focus and send attach command
  open -a Ghostty
  sleep 0.3
  osascript -e 'tell application "System Events" to keystroke "tmux attach -t Notes
" '
else
  # Ghostty not running — launch with tmux attach
  open -a Ghostty --args -e "tmux attach -t Notes"
fi
