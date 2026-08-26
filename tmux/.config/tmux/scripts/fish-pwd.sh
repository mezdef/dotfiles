#!/usr/bin/env bash
path="${1:-$PWD}"

# Replace $HOME prefix with ~
if [[ "$path" == "$HOME"* ]]; then
    path="~${path#$HOME}"
fi

IFS='/' read -ra parts <<< "$path"
result=""
count=${#parts[@]}

for ((i = 0; i < count; i++)); do
    part="${parts[$i]}"
    [[ -z "$part" ]] && continue
    if [[ "$part" == "~" ]]; then
        result="~"
    elif ((i == count - 1)); then
        result+="/${part}"
    else
        result+="/${part:0:1}"
    fi
done

echo "$result"
