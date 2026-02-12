#!/bin/bash

input=$(cat)
dir=$(basename "$(echo "$input" | jq -r '.workspace.current_dir')")
model=$(echo "$input" | jq -r '.model.display_name')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens')
total_tokens=$((total_in + total_out))
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')

# ANSI color codes
BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"

# Color code model name based on model type
model_colored="$model"
if [[ "$model" == *"Opus"* ]]; then
    model_colored="󰚩 ${MAGENTA}${model}${RESET}"
elif [[ "$model" == *"Sonnet"* ]]; then
    model_colored="󰚩 ${CYAN}${model}${RESET}"
elif [[ "$model" == *"Haiku"* ]]; then
    model_colored="󰚩 ${GREEN}${model}${RESET}"
else
    model_colored="󰚩 ${model}"
fi

# Color code context usage percentage based on usage level
context_color="$GREEN"
if (( $(echo "$used_pct >= 80" | bc -l) )); then
    context_color="$RED"
elif (( $(echo "$used_pct >= 60" | bc -l) )); then
    context_color="$YELLOW"
fi

printf "${BLUE}/%s${RESET} | %b | 󰮯 ${WHITE}%s${RESET} | 󰄉 %b%.1f%%%b" "$dir" "$model_colored" "$total_tokens" "$context_color" "$used_pct" "$RESET"
