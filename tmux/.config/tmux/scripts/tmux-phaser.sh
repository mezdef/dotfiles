#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  tmux-phaser                                                     ║
# ║  Unified session/window/pane switcher with fzf                  ║
# ║  Originally forked from github.com/Kristijan/fzf-pane-switch    ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Performance notes:
# - Colors, icons, and fzf version are cached to ~/.cache/tmux/ to avoid
#   expensive subprocess calls on every invocation (~400ms → ~100ms).
# - Icon cache is a TSV file mapping command names → nerd font glyphs.
#   New commands are appended on the fly; clear with --clear-cache.
# - Colors are resolved once from tmux theme vars (@thm_*) and cached
#   as pre-computed ANSI escape sequences.
# - fzf version is cached to skip two `fzf --version` calls (~58ms).
# - Run `tmux-phaser.sh --clear-cache` after theme or tool changes.


SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

command -v fzf >/dev/null 2>&1 || { echo "fzf not found"; exit 1; }

# ─── Configuration ────────────────────────────────────────────────

TOGGLE_KEY="ctrl-p"  # fzf key to dismiss popup (should match tmux bind)
PREVIEW_PANE=true
# Popup dimensions controlled by display-popup in tmux.conf (not fzf --tmux)
# to avoid the bell that run-shell triggers on completion.
FZF_PREVIEW_WINDOW_POSITION='right,,,nowrap'
NERD_FONT_BIN="$HOME/.config/tmux/plugins/tmux-nerd-font-window-name/bin/tmux-nerd-font-window-name"
CACHE_DIR="$HOME/.cache/tmux"

# ─── Cache Infrastructure ────────────────────────────────────────
# All caches live in ~/.cache/tmux/. They persist across invocations
# and are cleared together via --clear-cache.

mkdir -p "${CACHE_DIR}"

# Handle --clear-cache before anything else
if [[ "${1:-}" == "--clear-cache" ]]; then
  rm -f "${CACHE_DIR}/colors.sh" "${CACHE_DIR}/icon-cache.tsv" "${CACHE_DIR}/fzf-version"
  echo "Phaser cache cleared"
  exit 0
fi

# ─── Icons ──────────────────────────────────────────────────────
# Nerd font glyphs for list item types.

SESSION_ICON=""
WINDOW_ICON=""
ZOXIDE_ICON=""

# ─── Colors (cached) ───────────────────────────────────────────
# Resolves tmux theme variables (@thm_*) once and caches the ANSI
# escape sequences. Each `tmux show-option` call costs ~15ms, and
# we need 3 of them — caching saves ~45ms per invocation.

RESET=$'\033[0m'
hex_fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

COLOR_CACHE="${CACHE_DIR}/colors.sh"
if [[ -f "${COLOR_CACHE}" ]]; then
  source "${COLOR_CACHE}"
else
  _green=$(tmux show-option -gqv @thm_green 2>/dev/null | tr -d '#')
  _mauve=$(tmux show-option -gqv @thm_mauve 2>/dev/null | tr -d '#')
  _blue=$(tmux show-option -gqv @thm_blue 2>/dev/null | tr -d '#')
  SESSION_COLOR=$(hex_fg "${_green:-a6e3a1}")
  WINDOW_COLOR=$(hex_fg "${_mauve:-cba6f7}")
  ZOXIDE_COLOR=$(hex_fg "${_blue:-89b4fa}")
  # Write cache so next invocation skips the tmux show-option calls
  cat > "${COLOR_CACHE}" <<-CACHE
	SESSION_COLOR=$'${SESSION_COLOR}'
	WINDOW_COLOR=$'${WINDOW_COLOR}'
	ZOXIDE_COLOR=$'${ZOXIDE_COLOR}'
	CACHE
fi

# ─── Icon Cache (file-backed) ─────────────────────────────────
# The nerd-font binary takes ~80ms per call. We cache command→icon
# mappings in a TSV file so each command is only looked up once,
# ever. New commands are appended on the fly.

ICON_CACHE_FILE="${CACHE_DIR}/icon-cache.tsv"

# Load existing icon cache into an associative array
declare -A ICON_CACHE
if [[ -f "${ICON_CACHE_FILE}" ]]; then
  while IFS=$'\t' read -r cmd icon; do
    [[ -n "$cmd" ]] && ICON_CACHE["$cmd"]="$icon"
  done < "${ICON_CACHE_FILE}"
fi

# Look up an icon, using cache first, falling back to nerd-font binary
function pane_icon() {
  local cmd="$1"
  if [[ -n "${ICON_CACHE[$cmd]+x}" ]]; then
    echo "${ICON_CACHE[$cmd]}"
    return
  fi
  local icon=""
  if [[ -x "${NERD_FONT_BIN}" ]]; then
    icon=$("${NERD_FONT_BIN}" "$cmd" 2>/dev/null | awk '{print $1}')
  fi
  icon="${icon:-}"
  ICON_CACHE["$cmd"]="$icon"
  # Append to file cache for future invocations
  printf '%s\t%s\n' "$cmd" "$icon" >> "${ICON_CACHE_FILE}"
  echo "$icon"
}

# Resolve icons for all unique pane commands, only calling the binary
# for commands not already in the file cache.
function build_icon_cache() {
  local cmds
  cmds=$(tmux list-panes -aF '#{pane_current_command}' | sort -u)
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    # pane_icon handles cache hit/miss internally
    pane_icon "$cmd" > /dev/null
  done <<< "$cmds"
}

# ─── fzf Version (cached) ─────────────────────────────────────
# Two vercomp calls cost ~58ms due to `fzf --version` forks.
# Cache the version string — only changes on brew upgrade.

FZF_VERSION_CACHE="${CACHE_DIR}/fzf-version"
if [[ -f "${FZF_VERSION_CACHE}" ]]; then
  FZF_VERSION=$(< "${FZF_VERSION_CACHE}")
else
  FZF_VERSION=$(fzf --version | awk '{print $1}')
  echo "${FZF_VERSION}" > "${FZF_VERSION_CACHE}"
fi

# ─── Output Format ───────────────────────────────────────────────
# Each line is: TARGET_ID<TAB>ICON DISPLAY_TEXT
#
# Target ID encodes the type and tmux address:
#   S:session_name            → session
#   W:session_name:win_idx    → window
#   P:session_name:win.pane   → pane
#   Z:/absolute/path          → zoxide directory
#
# Tab delimiter ensures names with spaces don't break fzf's {1}.
# fzf shows only field 2+ (--with-nth=2..) so the ID is hidden.

TAB=$'\t'
SESSION_FORMAT="S:#{session_name}${TAB}#{session_name}"
WINDOW_FORMAT="W:#{session_name}:#{window_index}${TAB}#{session_name} | #{?#{==:#{window_name},Window},#I,#{window_name}}"
PANE_FORMAT="P:#{session_name}:#{window_index}.#{pane_index}${TAB}#{session_name} | #{?#{==:#{window_name},Window},#I,#{window_name}} | #{pane_current_command}"

# ─── Utilities ───────────────────────────────────────────────────

# Compare semver strings. Returns: 0=equal, 1=first newer, 2=second newer
function vercomp() {
  IFS='.' read -r -a ver1 <<< "$1"
  IFS='.' read -r -a ver2 <<< "$2"
  for i in 0 1 2; do
    local num1="${ver1[i]:-0}" num2="${ver2[i]:-0}"
    if ((num1 > num2)); then return 1
    elif ((num1 < num2)); then return 2; fi
  done
  return 0
}

# Convert target ID to a tmux -t target string
function resolve_target() {
  local raw="$1" type="${1%%:*}" rest="${1#*:}"
  case "${type}" in
    S) echo "=${rest}" ;;
    W) echo "=${rest%%:*}:${rest#*:}" ;;
    P) echo "=${rest}" ;;
  esac
}

# ─── List Generators ─────────────────────────────────────────────
# All list functions take the current session first, then remaining
# sessions alphabetically. This ordering is preserved by fzf via
# --tiebreak=index.

function list_sessions() {
  local current="$1"; shift
  local all_lines current_line=() other_lines=()
  while IFS= read -r line; do
    local name="${line%%${TAB}*}"; name="${name#S:}"
    if [[ "$name" == "$current" ]]; then
      current_line+=("$line")
    else
      other_lines+=("$line")
    fi
  done < <(tmux list-sessions -F "${SESSION_FORMAT}")
  for line in "${current_line[@]}" "${other_lines[@]}"; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
    echo "${id}${TAB}${SESSION_COLOR}${SESSION_ICON}${RESET} ${rest}"
  done
}

function list_windows() {
  local current="$1" current_window="$2"; shift 2
  local current_win_lines=() current_other_lines=() other_session_lines=()
  while IFS= read -r line; do
    local id="${line%%${TAB}*}"
    # id is W:session_name:window_index
    local session_and_win="${id#W:}"
    local session="${session_and_win%%:*}"
    local win="${session_and_win##*:}"
    if [[ "$session" == "$current" && "$win" == "$current_window" ]]; then
      current_win_lines+=("$line")
    elif [[ "$session" == "$current" ]]; then
      current_other_lines+=("$line")
    else
      other_session_lines+=("$line")
    fi
  done < <(tmux list-windows -aF "${WINDOW_FORMAT}")
  for line in "${current_win_lines[@]}" "${current_other_lines[@]}" "${other_session_lines[@]}"; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}"
    echo "${id}${TAB}${WINDOW_COLOR}${WINDOW_ICON}${RESET} ${rest}"
  done
}

function list_panes() {
  local current="$1" current_window="$2"; shift 2
  local current_win_lines=() current_other_lines=() other_session_lines=()
  while IFS= read -r line; do
    local id="${line%%${TAB}*}"
    # id is P:session_name:window_index.pane_index
    local session_and_rest="${id#P:}"
    local session="${session_and_rest%%:*}"
    local win_pane="${session_and_rest#*:}"
    local win="${win_pane%%.*}"
    if [[ "$session" == "$current" && "$win" == "$current_window" ]]; then
      current_win_lines+=("$line")
    elif [[ "$session" == "$current" ]]; then
      current_other_lines+=("$line")
    else
      other_session_lines+=("$line")
    fi
  done < <(tmux list-panes -aF "${PANE_FORMAT}")
  for line in "${current_win_lines[@]}" "${current_other_lines[@]}" "${other_session_lines[@]}"; do
    local id="${line%%${TAB}*}" rest="${line#*${TAB}}" cmd="${line##* }"
    local icon="${ICON_CACHE[${cmd}]:-}"
    echo "${id}${TAB}${icon} ${rest}"
  done
}

# Main list: all sessions → all windows → all panes (current session first)
function generate_list() {
  local current_session
  current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  [[ -z "${current_session}" ]] && current_session=$(tmux list-sessions -F '#{session_name}' | head -1)

  local current_window
  current_window=$(tmux display-message -p '#{window_index}' 2>/dev/null)

  local other_sessions
  mapfile -t other_sessions < <(tmux list-sessions -F '#{session_name}' | grep -vxF "${current_session}" | sort)

  build_icon_cache

  list_sessions "${current_session}" "${other_sessions[@]}"
  list_windows "${current_session}" "${current_window}" "${other_sessions[@]}"
  list_panes "${current_session}" "${current_window}" "${other_sessions[@]}"
}

# Zoxide list: directories ranked by frecency, paths shortened with ~/
function generate_zoxide_list() {
  local home; home=$(eval echo ~)
  zoxide query -l 2>/dev/null | while IFS= read -r dir; do
    local display="${dir/$home/\~}"
    echo "Z:${dir}${TAB}${ZOXIDE_COLOR}${ZOXIDE_ICON}${RESET} ${display}"
  done
}

# ─── Actions ─────────────────────────────────────────────────────

function kill_target() {
  local raw="$1" type="${1%%:*}" rest="${1#*:}"
  local target; target=$(resolve_target "${raw}")
  case "${type}" in
    S) tmux kill-session -t "${target}" && tmux display-message "Killed session: ${rest}" ;;
    W) tmux kill-window -t "${target}"  && tmux display-message "Killed window: ${rest}" ;;
    P) tmux kill-pane -t "${target}"    && tmux display-message "Killed pane: ${rest}" ;;
  esac
}

function rename_target() {
  local raw="$1" type="${1%%:*}"
  local target; target=$(resolve_target "${raw}")

  local label current_name
  case "${type}" in
    S) label="session"; current_name=$(tmux display-message -p -t "${target}" '#{session_name}' 2>/dev/null) ;;
    W) label="window";  current_name=$(tmux display-message -p -t "${target}" '#{window_name}' 2>/dev/null) ;;
    *) return ;;
  esac

  clear
  printf '\n  Rename %s: \033[1m%s\033[0m\n\n  New name: ' "${label}" "${current_name}"
  local name; read -r name
  [[ -z "${name}" ]] && return

  case "${type}" in
    S) tmux rename-session -t "${target}" "${name}" && tmux display-message "Renamed session: ${current_name} → ${name}" ;;
    W) tmux rename-window -t "${target}" "${name}"  && tmux display-message "Renamed window: ${current_name} → ${name}" ;;
  esac
}

function preview_target() {
  local raw="$1" lines="${2:-30}" type="${1%%:*}"
  case "${type}" in
    Z) ls -la "${raw#Z:}" 2>/dev/null ;;
    *)
      local target; target=$(resolve_target "${raw}")
      tmux capture-pane -ep -S "-${lines}" -t "${target}" 2>/dev/null | \
        awk '{a[NR]=$0} END{for(i=NR;i>0;i--) if(a[i]~/[^ \t]/){for(j=1;j<=i;j++) print a[j]; exit}}' | \
        tail -n "${lines}"
      ;;
  esac
}

# ─── Subcommands ─────────────────────────────────────────────────
# Called by fzf binds via execute-silent/execute/reload.

# Parse --toggle-key before subcommands so it can be combined with normal invocation
if [[ "${1:-}" == "--toggle-key" ]]; then
  TOGGLE_KEY="$2"; shift 2
fi

case "${1:-}" in
  --list)    generate_list; exit 0 ;;
  --zoxide)  generate_zoxide_list; exit 0 ;;
  --kill)    kill_target "$2"; exit 0 ;;
  --rename)  rename_target "$2"; exit 0 ;;
  --resolve) resolve_target "$2"; exit 0 ;;
  --preview) preview_target "$2" "${3:-30}"; exit 0 ;;
esac

# ─── Main: fzf Picker ───────────────────────────────────────────

function main() {
  local current_pane
  current_pane=$(tmux display-message -p '#{pane_id}')

  # Core fzf options (no --tmux; popup is provided by display-popup in tmux.conf)
  local -a fzf_args=(
    --ansi --exit-0 --tiebreak=index
    --delimiter "\t"
    --with-nth=2..
    --header "  C-d kill  C-r rename  C-f zoxide  C-b back  ? preview  ${TOGGLE_KEY} close"
  )

  # Keybindings
  fzf_args+=(
    --bind "ctrl-d:execute-silent(${SCRIPT_PATH} --kill {1})+reload(${SCRIPT_PATH} --list)"
    --bind "ctrl-r:execute(${SCRIPT_PATH} --rename {1})+clear-query+reload(${SCRIPT_PATH} --list)"
    --bind "ctrl-f:change-prompt(  Zoxide: )+reload(${SCRIPT_PATH} --zoxide)+clear-query"
    --bind "ctrl-b:change-prompt(  Search: )+reload(${SCRIPT_PATH} --list)+clear-query"
    --bind "?:toggle-preview"
    --bind "${TOGGLE_KEY}:abort"  # Toggle: opens popup (tmux.conf), closes it (fzf abort)
  )

  # Conditional fzf features based on cached version
  vercomp '0.58.0' "${FZF_VERSION}"
  if [[ $? -ne 1 ]]; then
    fzf_args+=(--input-border --input-label=" Search " --info=inline-right)
    fzf_args+=(--list-border --list-label=" Phaser ")
    fzf_args+=(--preview-border --preview-label=" Preview ")
  fi

  vercomp '0.61.0' "${FZF_VERSION}"
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

  # Launch fzf (--print-query gives us the search text for new session creation)
  local fzf_output query selection target_raw
  fzf_output=$(generate_list | fzf --print-query "${fzf_args[@]}") || true

  query=$(echo "${fzf_output}" | sed -n '1p')
  selection=$(echo "${fzf_output}" | sed -n '2p')
  target_raw=$(echo "${selection}" | awk -F'\t' '{print $1}')

  # ── Handle selection ──────────────────────────────────────────

  if [[ -n "${target_raw}" && "${target_raw}" == Z:* ]]; then
    # Zoxide: create or switch to session at directory
    local dir="${target_raw#Z:}"
    local session_name="${dir##*/}"
    if tmux has-session -t "=${session_name}" 2>/dev/null; then
      tmux switch-client -t "=${session_name}"
    else
      tmux new-session -d -s "${session_name}" -c "${dir}" \
        && tmux switch-client -t "=${session_name}" \
        && tmux display-message "Created session: ${session_name}"
    fi

  elif [[ -n "${target_raw}" ]]; then
    # Existing session/window/pane: switch to it
    local target; target=$(resolve_target "${target_raw}")
    tmux switch-client -t "${target}" 2>/dev/null

  elif [[ -n "${query}" ]]; then
    # No match: create new session with search text as name
    tmux new-session -d -s "${query}" \
      && tmux switch-client -t "=${query}" \
      && tmux display-message "Created session: ${query}"

  else
    # Cancelled: stay where we are
    tmux switch-client -t "${current_pane}"
  fi
}

main
