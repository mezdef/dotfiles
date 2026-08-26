#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  herdr-phaser                                                    ║
# ║  Unified space/tab/pane/agent switcher with fzf                  ║
# ║  Port of tmux-phaser.sh (~/.config/tmux/scripts/tmux-phaser.sh)  ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Bound to alt+p as a herdr popup (see ../config.toml, [[keys.command]]).
#
# Unlike the tmux original this needs no caching layer: `herdr api snapshot`
# returns spaces, tabs, panes and agents in a single ~10ms call, where tmux
# needed one show-option/list-* fork per field.

set -uo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
HERDR="${HERDR_BIN_PATH:-herdr}"

command -v fzf >/dev/null 2>&1 || { echo "fzf not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found"; exit 1; }

# ─── Configuration ────────────────────────────────────────────────

TOGGLE_KEY="alt-p"   # dismisses the popup; matches the herdr keybind
FZF_PREVIEW_WINDOW_POSITION='right,50%,,nowrap,hidden'

# ─── Icons ────────────────────────────────────────────────────────
# Geometric marks rather than nerd font glyphs, matching herdr's own
# sidebar vocabulary. Agent state marks live in the jq `mark` def below.

SPACE_ICON="◉"
TAB_ICON="▸"
PANE_ICON="▪"
SEP="│"

# ─── Colors ───────────────────────────────────────────────────────
# Catppuccin mocha, matching theme.name in config.toml.

RESET=$'\033[0m'
hex_fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

C_SPACE=$(hex_fg a6e3a1)    # green
C_TAB=$(hex_fg cba6f7)      # mauve
C_PANE=$(hex_fg 89b4fa)     # blue
C_AGENT=$(hex_fg fab387)    # peach
C_DIM=$(hex_fg 6c7086)      # overlay0, separators
C_TEXT=$(hex_fg cdd6f4)     # fg

# ─── Snapshot ─────────────────────────────────────────────────────

snapshot() { "$HERDR" api snapshot; }

# ─── Output Format ────────────────────────────────────────────────
# Each line is: TARGET_ID<TAB>ICON DISPLAY
#
# Target ID encodes the type and herdr public id:
#   W:w1       → space (workspace)
#   T:w1:t1    → tab
#   P:w1:p1    → pane
#   A:w1:p1    → agent (the pane hosting it)
#
# Tab delimiter keeps labels with spaces intact; fzf shows field 2+
# (--with-nth=2..) so the id stays hidden.

generate_list() {
  snapshot | jq -r \
    --arg si "$SPACE_ICON" --arg ti "$TAB_ICON" --arg pi "$PANE_ICON" --arg sep "$SEP" \
    --arg cs "$C_SPACE" --arg ct "$C_TAB" --arg cp "$C_PANE" --arg ca "$C_AGENT" \
    --arg cd "$C_DIM" --arg cx "$C_TEXT" --arg rst "$RESET" '
    .result.snapshot as $s
    | ($s.focused_workspace_id // "") as $fw
    | ($s.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $wsl
    | ($s.tabs       | map({key: .tab_id,       value: .label}) | from_entries) as $tbl
    | (def mark($st): if $st == "working" then "◐"
                      elif $st == "done" then "✓"
                      elif $st == "blocked" then "●"
                      elif $st == "idle" then "○"
                      else "◌" end;
       def home($p): ($p // "") | sub("^" + env.HOME; "~");
       def cur: if .workspace_id == $fw then 0 else 1 end;
       def dim($t): $cd + $t + $rst;

       ($s.workspaces | sort_by([cur, .number]) | map(
          "W:" + .workspace_id + "\t"
          + $cs + $si + $rst + " " + $cx + .label + $rst
          + " " + dim($sep) + " " + dim(mark(.agent_status) + " " + (.tab_count|tostring) + (if .tab_count == 1 then " tab" else " tabs" end))
        )),
       ($s.tabs | sort_by([cur, .number]) | map(
          "T:" + .tab_id + "\t"
          + $ct + $ti + $rst + " " + $cx + ($wsl[.workspace_id] // .workspace_id) + $rst
          + " " + dim($sep) + " " + $cx + .label + $rst
        )),
       ($s.panes | sort_by([cur, .pane_id]) | map(
          "P:" + .pane_id + "\t"
          + $cp + $pi + $rst + " " + $cx + ($wsl[.workspace_id] // .workspace_id) + $rst
          + " " + dim($sep) + " " + $cx + ($tbl[.tab_id] // .tab_id) + $rst
          + " " + dim($sep) + " "
          + dim(home(if (.terminal_title_stripped // "") == "" then .cwd else .terminal_title_stripped end))
        )),
       ($s.agents | sort_by([cur, .pane_id]) | map(
          "A:" + .pane_id + "\t"
          + $ca + mark(.agent_status) + $rst + " " + $cx + .agent + $rst
          + " " + dim($sep) + " " + $cx + ($wsl[.workspace_id] // .workspace_id) + $rst
          + " " + dim($sep) + " " + dim(home(.terminal_title_stripped // .agent_status))
        ))
      )
    | flatten | .[]
  '
}

# ─── Preview ──────────────────────────────────────────────────────
# Spaces and tabs preview the focused pane of their active tab.

resolve_pane() {
  local type="${1%%:*}" rest="${1#*:}"
  case "$type" in
    P|A) echo "$rest"; return 0 ;;
  esac
  # layouts only carries each space's *active* tab, so resolve through panes[]
  snapshot | jq -r --arg type "$type" --arg id "$rest" '
    .result.snapshot as $s
    | (if $type == "W"
       then ($s.workspaces[] | select(.workspace_id == $id) | .active_tab_id)
       else $id end) as $t
    | [$s.panes[] | select(.tab_id == $t)]
    | (map(select(.focused)) + .)
    | .[0].pane_id // empty'
}

preview_target() {
  local pane lines="${2:-40}"
  pane=$(resolve_pane "$1")
  [[ -z "$pane" ]] && return 0
  # A pane's viewport is mostly trailing blank rows, so read generously and
  # trim them before tailing (same awk phaser uses on capture-pane output).
  local out
  out=$("$HERDR" pane read "$pane" --lines $((lines * 4)) 2>/dev/null |
    awk '{a[NR]=$0} END{for(i=NR;i>0;i--) if(a[i]~/[^ \t]/){for(j=1;j<=i;j++) print a[j]; exit}}' |
    tail -n "$lines")

  # Restored panes that have produced no output read back empty; show what we
  # know about them instead of an empty box.
  if [[ -z "${out//[[:space:]]/}" ]]; then
    snapshot | jq -r --arg p "$pane" '
      .result.snapshot.panes[] | select(.pane_id == $p)
      | "  " + $p + "\n  " + (.cwd // "?") + "\n\n  (no output yet)"'
    return 0
  fi
  printf '%s\n' "$out"
}

# ─── Focus ────────────────────────────────────────────────────────
# herdr exposes no focus-pane-by-id: the API has pane.focus_direction only.
# So agent panes route through `agent focus` (which accepts a pane id) and
# plain panes fall back to focusing their tab.
#
# A popup is also a session modal. If herdr refuses the call while the popup
# is still up, retry detached so it lands after the popup closes.

focus_target() {
  local type="${1%%:*}" rest="${1#*:}" cmd target out

  case "$type" in
    W) cmd="workspace"; target="$rest" ;;
    T) cmd="tab";       target="$rest" ;;
    A) cmd="agent";     target="$rest" ;;
    P)
      read -r cmd target < <(snapshot | jq -r --arg p "$rest" '
        .result.snapshot as $s
        | if ($s.agents | any(.pane_id == $p))
          then "agent " + $p
          else "tab " + (($s.panes[] | select(.pane_id == $p) | .tab_id) // "")
          end')
      ;;
    *) return 1 ;;
  esac

  [[ -z "${target:-}" ]] && return 1

  if out=$("$HERDR" "$cmd" focus "$target" 2>&1) && [[ "$out" != *'"error"'* ]]; then
    return 0
  fi
  ( sleep 0.15; "$HERDR" "$cmd" focus "$target" >/dev/null 2>&1 ) &
}

# ─── Subcommands ──────────────────────────────────────────────────
# Called by fzf binds via execute/reload, and by the main flow.

case "${1:-}" in
  --list)    generate_list; exit 0 ;;
  --preview) preview_target "$2" "${3:-40}"; exit 0 ;;
  --focus)   focus_target "$2"; exit 0 ;;
esac

# ─── Main: fzf Picker ─────────────────────────────────────────────

main() {
  local -a fzf_args=(
    --ansi --exit-0 --tiebreak=index
    --delimiter "\t"
    --with-nth=2..
    --header "  ? preview  ${TOGGLE_KEY} close"
    --input-border --input-label=" Search " --info=inline-right
    --list-border --list-label=" Herdr "
    --preview-border --preview-label=" Preview "
    --ghost "type to search..."
    --bind "?:toggle-preview"
    --bind "${TOGGLE_KEY}:abort"
    --preview "${SCRIPT_PATH} --preview {1} \${FZF_PREVIEW_LINES:-40}"
    --preview-window "${FZF_PREVIEW_WINDOW_POSITION}"
  )

  local selection target
  selection=$(generate_list | fzf "${fzf_args[@]}") || exit 0
  target=$(printf '%s' "$selection" | awk -F'\t' '{print $1}')
  [[ -n "$target" ]] && focus_target "$target"
}

main
