#!/usr/bin/env bash
# Open current tmux pane scrollback in nvim (read-only, cursor at bottom)
file="/tmp/tmux-scrollback-${TMUX_PANE}"
tmux capture-pane -S - -E - -e -p > "$file"
nvim -c "terminal cat '$file'" -c 'norm G' -c 'nnoremap <buffer> q <cmd>q!<cr>'
