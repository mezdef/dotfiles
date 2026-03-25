#!/usr/bin/env bash
# tmux-teleport: unified session/window/pane switcher
# Forked from https://github.com/Kristijan/fzf-pane-switch.tmux

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

command -v fzf >/dev/null 2>&1 || {
  echo "fzf not found"
  exit 1
}

# Config
PREVIEW_PANE=true
FZF_WINDOW_POSITION='center,70%,80%'
FZF_PREVIEW_WINDOW_POSITION='right,,,nowrap'
NERD_FONT_BIN="$HOME/.config/tmux/plugins/tmux-nerd-font-window-name/bin/tmux-nerd-font-window-name"

# Icons
SESSION_ICON=""
WINDOW_ICON=""

# Colors: try tmux theme vars, fall back to catppuccin mocha hex
RESET=$'\033[0m'
hex_fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
_green=$(tmux show-option -gqv @thm_green 2>/dev/null | tr -d '#')
_mauve=$(tmux show-option -gqv @thm_mauve 2>/dev/null | tr -d '#')
SESSION_COLOR=$(hex_fg "${_green:-a6e3a1}")
WINDOW_COLOR=$(hex_fg "${_mauve:-cba6f7}")

# Hidden first field format: TYPE:session:window_index:pane_index
# Tab-delimited so session names with spaces don't break {1}
TAB=$'\t'
SESSION_FORMAT="S:#{session_name}${TAB}#{session_name}"
WINDOW_FORMAT="W:#{session_name}:#{window_index}${TAB}#{session_name} | #{?#{==:#{window_name},Window},#I,#{window_name}}"
PANE_FORMAT="P:#{session_name}:#{window_index}.#{pane_index}${TAB}#{session_name} | #{?#{==:#{window_name},Window},#I,#{window_name}} | #{pane_current_command}"

function vercomp() {
  IFS='.' read -r -a ver1 <<<"$1"
  IFS='.' read -r -a ver2 <<<"$2"
  for i in 0 1 2; do
    local num1="${ver1[i]:-0}" num2="${ver2[i]:-0}"
    if ((num1 > num2)); then
      return 1
    elif ((num1 < num2)); then return 2; fi
  done
  return 0
}

function pane_icon() {
  if [[ -x "${NERD_FONT_BIN}" ]]; then
    "${NERD_FONT_BIN}" "$1" 2>/dev/null | awk '{print $1}'
  else
    echo ""
  fi
}

function list_sessions() {
  local current="$1"
  shift
  tmux list-sessions -F "${SESSION_FORMAT}" -f "#{==:#{session_name},${current}}" | while IFS= read -r line; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
    echo "${id}${TAB}${SESSION_COLOR}${SESSION_ICON}${RESET} ${rest}"
  done
  for s in "$@"; do
    tmux list-sessions -F "${SESSION_FORMAT}" -f "#{==:#{session_name},${s}}" | while IFS= read -r line; do
      local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
      echo "${id}${TAB}${SESSION_COLOR}${SESSION_ICON}${RESET} ${rest}"
    done
  done
}

function list_windows() {
  local current="$1"
  shift
  tmux list-windows -F "${WINDOW_FORMAT}" -t "=${current}" | while IFS= read -r line; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
    echo "${id}${TAB}${WINDOW_COLOR}${WINDOW_ICON}${RESET} ${rest}"
  done
  for s in "$@"; do
    tmux list-windows -F "${WINDOW_FORMAT}" -t "=${s}" | while IFS= read -r line; do
      local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
      echo "${id}${TAB}${WINDOW_COLOR}${WINDOW_ICON}${RESET} ${rest}"
    done
  done
}

function list_panes() {
  local current="$1"
  shift
  tmux list-panes -sF "${PANE_FORMAT}" -t "=${current}" | while IFS= read -r line; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}" cmd="${line##* }"
    local icon
    icon=$(pane_icon "${cmd}")
    echo "${id}${TAB}${icon} ${rest}"
  done
  for s in "$@"; do
    tmux list-panes -sF "${PANE_FORMAT}" -t "=${s}" | while IFS= read -r line; do
      local id="${line%%${TAB}*}" rest="${line#*${TAB}}" cmd="${line##* }"
      local icon
      icon=$(pane_icon "${cmd}")
      echo "${id}${TAB}${icon} ${rest}"
    done
  done
}

function generate_list() {
  local current_session
  current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  [[ -z "${current_session}" ]] && current_session=$(tmux list-sessions -F '#{session_name}' | head -1)

  local other_sessions
  mapfile -t other_sessions < <(tmux list-sessions -F '#{session_name}' | grep -vxF "${current_session}" | sort)

  list_sessions "${current_session}" "${other_sessions[@]}"
  list_windows "${current_session}" "${other_sessions[@]}"
  list_panes "${current_session}" "${other_sessions[@]}"
}

# Parse target ID field (e.g. S:Dotfiles, W:Dotfiles:1, P:Dotfiles:1.0)
# into a tmux target string
function resolve_target() {
  local raw="$1"
  local type="${raw%%:*}"
  local rest="${raw#*:}"
  case "${type}" in
  S) echo "=${rest}" ;;
  W) echo "=${rest%%:*}:${rest#*:}" ;;
  P) echo "=${rest}" ;;
  esac
}

function kill_target() {
  local raw="$1"
  local type="${raw%%:*}"
  local rest="${raw#*:}"
  local target
  target=$(resolve_target "${raw}")
  case "${type}" in
  S) tmux kill-session -t "${target}" && tmux display-message "Killed session: ${rest}" ;;
  W) tmux kill-window -t "${target}" && tmux display-message "Killed window: ${rest}" ;;
  P) tmux kill-pane -t "${target}" && tmux display-message "Killed pane: ${rest}" ;;
  esac
}

function rename_target() {
  local raw="$1"
  local type="${raw%%:*}"
  local target
  target=$(resolve_target "${raw}")

  local label current_name
  case "${type}" in
  S)
    label="session"
    current_name=$(tmux display-message -p -t "${target}" '#{session_name}' 2>/dev/null)
    ;;
  W)
    label="window"
    current_name=$(tmux display-message -p -t "${target}" '#{window_name}' 2>/dev/null)
    ;;
  *) return ;;
  esac

  # Clear previous output then prompt
  clear
  printf '\n  Rename %s: \033[1m%s\033[0m\n\n  New name: ' "${label}" "${current_name}"
  local name
  read -r name
  [[ -z "${name}" ]] && return
  case "${type}" in
  S) tmux rename-session -t "${target}" "${name}" && tmux display-message "Renamed session: ${current_name} → ${name}" ;;
  W) tmux rename-window -t "${target}" "${name}" && tmux display-message "Renamed window: ${current_name} → ${name}" ;;
  esac
}

function preview_target() {
  local raw="$1" lines="${2:-30}"
  local type="${raw%%:*}"
  case "${type}" in
  Z)
    # Zoxide path — show directory listing
    local dir="${raw#Z:}"
    ls -la "${dir}" 2>/dev/null
    ;;
  *)
    local target
    target=$(resolve_target "${raw}")
    tmux capture-pane -ep -S "-${lines}" -t "${target}" 2>/dev/null |
      awk '{a[NR]=$0} END{for(i=NR;i>0;i--) if(a[i]~/[^ \t]/){for(j=1;j<=i;j++) print a[j]; exit}}' |
      tail -n "${lines}"
    ;;
  esac
}

function generate_zoxide_list() {
  local _blue
  _blue=$(tmux show-option -gqv @thm_blue 2>/dev/null | tr -d '#')
  local ZOXIDE_COLOR
  ZOXIDE_COLOR=$(hex_fg "${_blue:-89b4fa}")
  local ZOXIDE_ICON=" "

  local home
  home=$(eval echo ~)
  zoxide query -l 2>/dev/null | while IFS= read -r dir; do
    local display="${dir/$home/\~}"
    echo "Z:${dir}${TAB}${ZOXIDE_COLOR}${ZOXIDE_ICON}${RESET} ${display}"
  done
}

# Handle subcommands (called by fzf binds)
case "${1}" in
--list)
  generate_list
  exit 0
  ;;
--zoxide)
  generate_zoxide_list
  exit 0
  ;;
--kill)
  kill_target "$2"
  exit 0
  ;;
--rename)
  rename_target "$2"
  exit 0
  ;;
--resolve)
  resolve_target "$2"
  exit 0
  ;;
--preview)
  preview_target "$2" "$3"
  exit 0
  ;;
esac

function select_pane() {
  local current_pane
  current_pane=$(tmux display-message -p '#{pane_id}')

  local -a fzf_args=(
    --ansi --exit-0 --tiebreak=index
    --delimiter "\t"
    --tmux "${FZF_WINDOW_POSITION}"
    --with-nth=2..
    --header "  C-d kill  C-r rename  C-f zoxide  C-b back  ? preview"
    --bind "ctrl-d:execute-silent(${SCRIPT_PATH} --kill {1})+reload(${SCRIPT_PATH} --list)"
    --bind "ctrl-r:execute(${SCRIPT_PATH} --rename {1})+clear-query+reload(${SCRIPT_PATH} --list)"
    --bind "ctrl-f:change-prompt(  Zoxide: )+reload(${SCRIPT_PATH} --zoxide)+clear-query"
    --bind "ctrl-b:change-prompt(  Search: )+reload(${SCRIPT_PATH} --list)+clear-query"
    --bind "?:toggle-preview"
  )

  # Border styling based on fzf version
  local fzf_version
  fzf_version=$(fzf --version | awk '{print $1}')
  vercomp '0.58.0' "${fzf_version}"
  if [[ $? -ne 1 ]]; then
    fzf_args+=(--input-border --input-label=" Search " --info=inline-right)
    fzf_args+=(--list-border --list-label=" Teleport ")
    fzf_args+=(--preview-border --preview-label=" Preview ")
  fi
  vercomp '0.61.0' "${fzf_version}"
  if [[ $? -ne 1 ]]; then
    fzf_args+=(--ghost "type to search...")
  fi

  # Preview pane
  if [[ "${PREVIEW_PANE}" = 'true' ]]; then
    fzf_args+=(
      --preview "${SCRIPT_PATH} --preview {1} \${FZF_PREVIEW_LINES:-30}"
      --preview-window "${FZF_PREVIEW_WINDOW_POSITION}"
    )
  fi

  local fzf_output query selection target_raw target
  fzf_output=$(generate_list | fzf --print-query "${fzf_args[@]}")

  query=$(echo "${fzf_output}" | sed -n '1p')
  selection=$(echo "${fzf_output}" | sed -n '2p')
  target_raw=$(echo "${selection}" | awk -F'\t' '{print $1}')

  if [[ -n "${target_raw}" && "${target_raw}" == Z:* ]]; then
    # Zoxide path — create session at directory
    local dir="${target_raw#Z:}"
    local session_name="${dir##*/}"
    # If session already exists, just switch to it
    if tmux has-session -t "=${session_name}" 2>/dev/null; then
      tmux switch-client -t "=${session_name}"
    else
      tmux new-session -d -s "${session_name}" -c "${dir}" && tmux switch-client -t "=${session_name}" && tmux display-message "Created session: ${session_name}"
    fi
  elif [[ -n "${target_raw}" ]]; then
    # Item selected — switch to it
    target=$(resolve_target "${target_raw}")
    tmux switch-client -t "${target}" 2>/dev/null
  elif [[ -n "${query}" ]]; then
    # No match — create new session with query as name
    tmux new-session -d -s "${query}" && tmux switch-client -t "=${query}" && tmux display-message "Created session: ${query}"
  else
    tmux switch-client -t "${current_pane}"
  fi
}

select_pane
