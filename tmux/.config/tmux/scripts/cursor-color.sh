#!/bin/bash
# Usage: cursor-color.sh <hex_color>
# Sends an OSC 12 cursor color escape sequence to the active pane's tty
pane_tty=$(tmux display-message -p '#{pane_tty}')
printf '\033]12;%s\007' "$1" > "$pane_tty"
