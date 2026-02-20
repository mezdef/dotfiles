#!/bin/bash

# cd to pane path if provided
[ -n "$1" ] && cd "$1" || true

# Exit silently if not in a jj repo
jj root >/dev/null 2>&1 || exit 0

change_id=$(jj log -r @ --no-graph -T 'change_id.shortest()' 2>/dev/null)
description=$(jj log -r @ --no-graph -T 'if(description, description.first_line(), "(no description)")' 2>/dev/null)

echo "${change_id} ${description}"
