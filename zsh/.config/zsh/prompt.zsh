# Pure zsh prompt — replaces starship to eliminate ~28ms of per-prompt fork cost.
# Starship forks its binary twice per prompt (PROMPT + RPROMPT). This pure zsh
# implementation renders in <1ms with zero forks.
#
# Layout:
#   LEFT:  󱨊          (white on success, red on error)
#   RIGHT: directory   (blue, zoxide name or fish-style path) + duration (yellow, if >=2s)
#
# Requires: theme.zsh sourced first (provides CAT_* hex values)

setopt promptsubst
zmodload zsh/datetime
autoload -Uz add-zsh-hook

# Pre-compute ANSI escape sequences from hex colors at source time.
# This avoids forking printf on every prompt render — the escapes are baked
# into variables once and reused via %{...%} prompt escapes.
_hex_fg() { printf '\e[38;2;%d;%d;%dm' 0x${1:1:2} 0x${1:3:2} 0x${1:5:2}; }
_RST=$'\e[0m'
_CLR_TEXT="$(_hex_fg "$CAT_TEXT")"
_CLR_RED="$(_hex_fg "$CAT_RED")"
_CLR_GREEN="$(_hex_fg "$CAT_GREEN")"
_CLR_MAUVE="$(_hex_fg "$CAT_MAUVE")"
_CLR_BLUE="$(_hex_fg "$CAT_BLUE")"
_CLR_YELLOW="$(_hex_fg "$CAT_YELLOW")"
unfunction _hex_fg

# Symbol colour by vi mode, keyed on zsh-vi-mode's $ZVM_MODE (n/i/v/vl/r).
# Looked up during prompt expansion so mode changes cost no forks. The cursor
# colour below does the same job, but multiplexers swallow OSC 12, so the
# symbol is the indicator that actually survives tmux and herdr.
typeset -A _CLR_MODE
_CLR_MODE=(
  n  "$_CLR_GREEN"
  i  "$_CLR_TEXT"
  v  "$_CLR_MAUVE"
  vl "$_CLR_MAUVE"
  r  "$_CLR_RED"
)

# --- Command duration & exit status tracking ---
# _PROMPT_CMD_RAN guards against coloring the first prompt red due to non-zero
# $? from shell init (compinit, plugin sourcing, etc.)
_PROMPT_SYMBOL_STATUS=0
_prompt_preexec() { _PROMPT_START=$EPOCHREALTIME; }
_prompt_precmd() {
  local last_status=$?

  # Duration: only show if command took >= 2 seconds
  if (( ${+_PROMPT_START} )); then
    local dur=$(( EPOCHREALTIME - _PROMPT_START ))
    unset _PROMPT_START
    if (( dur >= 2 )); then
      _PROMPT_DURATION=" $(( ${dur%.*} ))s"
    else
      _PROMPT_DURATION=""
    fi
  else
    _PROMPT_DURATION=""
  fi

  # Exit status: skip on first prompt (before any command has run)
  if (( ${+_PROMPT_CMD_RAN} )); then
    _PROMPT_SYMBOL_STATUS=$last_status
  fi
  _PROMPT_CMD_RAN=1

  # A failed command overrides the vi-mode colour until the next command runs.
  if (( _PROMPT_SYMBOL_STATUS == 0 )); then
    _PROMPT_ERR=
  else
    _PROMPT_ERR="$_CLR_RED"
  fi
}
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd

# --- Directory display ---
# If zoxide recognises the current directory (score > 0), show just the folder
# name (e.g. "dotfiles"). Otherwise fall back to fish-style abbreviated path
# (e.g. "~/d/s/current"). Uses zoxide query --score to check without forking
# on every prompt — only recalculates on directory change (chpwd hook).
_prompt_update_dir() {
  local dir="${PWD/#$HOME/~}"
  # Check if zoxide knows this directory (has a score for the basename)
  if zoxide query "${dir:t}" &>/dev/null; then
    _PROMPT_DIR="${dir:t}"
  else
    # Fish-style: abbreviate all but the last path component to first letter
    local parts=("${(@s:/:)dir}")
    _PROMPT_DIR=""
    local i
    for (( i=1; i < ${#parts}; i++ )); do
      _PROMPT_DIR+="${parts[$i][1]}/"
    done
    _PROMPT_DIR+="${parts[-1]}"
  fi
}
add-zsh-hook chpwd _prompt_update_dir
_prompt_update_dir

PROMPT='%{${_PROMPT_ERR:-${_CLR_MODE[${ZVM_MODE:-i}]}}%}󱨊%{$_RST%} '
RPROMPT='%{$_CLR_BLUE%}${_PROMPT_DIR}%{$_RST%}${_PROMPT_DURATION:+%{$_CLR_YELLOW%\}$_PROMPT_DURATION%{$_RST%\}}'

# --- Vi mode cursor ---
# Block cursor in both modes; green in normal mode, white in insert mode.
# \e[1 q = block cursor, \e]12;COLOR\a = set cursor color (xterm OSC 12).
zle-keymap-select() {
  # Deliberately switching out of insert clears the error colour so the symbol
  # can show the mode again. line-init's forced `zle -K viins` is a viins
  # transition, so it leaves a fresh error colour intact.
  [[ ${KEYMAP} != viins ]] && _PROMPT_ERR=
  if [[ ${KEYMAP} == vicmd || $1 == 'block' ]]; then
    echo -ne "\e[1 q\e]12;${CAT_GREEN}\a"
  else
    echo -ne "\e[1 q\e]12;${CAT_TEXT}\a"
  fi
  zle reset-prompt
}
zle -N zle-keymap-select
# Named function (not a same-name widget) so zsh-vi-mode's zvm_define_widget
# sees 4 fields from `zle -l -L` and wraps this instead of replacing it.
_prompt_zle_line_init() {
  zle -K viins
  echo -ne "\e[1 q\e]12;${CAT_TEXT}\a"
}
zle -N zle-line-init _prompt_zle_line_init
echo -ne "\e[1 q\e]12;${CAT_TEXT}\a"
preexec() { echo -ne "\e[1 q\e]12;${CAT_TEXT}\a"; }
