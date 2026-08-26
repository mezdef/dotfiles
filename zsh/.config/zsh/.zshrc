# .zshrc — sourced for interactive shells.
# Main config: history, plugins, prompt, tools, aliases.
# Machine-specific overrides go in .zshrc.local (git-ignored).
# See .zshenv for the full file map.

################################################################################
# History
################################################################################

HISTFILE=~/.cache/zsh/.zsh_history
export SAVEHIST=1000000
export HISTSIZE=$SAVEHIST
setopt HIST_IGNORE_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_NO_STORE
setopt HIST_IGNORE_SPACE
setopt append_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt share_history

################################################################################
# Init Caching
################################################################################

# Runs a command once and caches its stdout to ~/.cache/zsh/<name>.
# Subsequent shells source the cached file instead of forking the command.
# Saves ~10ms per cached tool (starship, carapace, zoxide, fzf each fork on init).
# Clear caches with: rm ~/.cache/zsh/*.zsh (or use the `rr` alias).
_cache_init() {
  local cache="$HOME/.cache/zsh/$1"; shift
  if [[ ! -f "$cache" || ! -s "$cache" ]]; then
    mkdir -p "${cache:h}"
    "$@" > "$cache"
  fi
  source "$cache"
}

# Regenerate completion dump at most once per day (-C skips security check).
# Full compinit runs ~15ms; cached compinit -C runs ~3ms.
autoload -U compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit -d "$ZDOTDIR/.zcompdump"
else
  compinit -C -d "$ZDOTDIR/.zcompdump"
fi

################################################################################
# Plugins
################################################################################

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-patina: Rust-daemon syntax highlighter, replaces zsh-syntax-highlighting.
# ~5ms lower input_lag (1.9ms vs 7ms) due to async daemon architecture.
_cache_init zsh-patina.zsh /opt/homebrew/bin/zsh-patina activate

################################################################################
# Prompt & Vi Mode
################################################################################

source "$ZDOTDIR/theme.zsh"
source "$ZDOTDIR/prompt.zsh" # prompt symbol, directory, cmd duration, vi cursor colors

# Vi mode with instant mode switching
bindkey -v
export KEYTIMEOUT=1

# zsh-vi-mode — text objects, surround, real visual mode. Config vars must be
# set before sourcing; zvm_init itself runs at the first prompt.
# LAZY_KEYBINDINGS=false binds vicmd/visual during init instead of on the first
# ESC, so the zvm_after_init overrides below aren't clobbered later.
ZVM_LAZY_KEYBINDINGS=false
# prompt.zsh owns the cursor (block in both modes, green normal / white insert).
ZVM_CURSOR_STYLE_ENABLED=false
# Yank to macOS clipboard — auto-detects pbcopy/pbpaste. Replaces the hand-rolled
# vi-yank-clip widgets and also covers yiw/y$/visual-y, not just y and Y.
ZVM_SYSTEM_CLIPBOARD_ENABLED=true
# Visual-mode selection highlight. The plugin has no theme integration, just raw
# hex, so wire it to catppuccin from theme.zsh (default is a hardcoded #cc0000).
ZVM_VI_HIGHLIGHT_BACKGROUND=$CAT_MAUVE
ZVM_VI_HIGHLIGHT_FOREGROUND=$CAT_BASE
source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT # start every line in insert, as before

# zvm_init rebinds the keymaps at the first prompt, so re-apply our bindings
# after it: zvm takes viins ^R for history-incremental-search-backward, and
# vicmd / and ? need the same native restore as the atuin section below.
zvm_after_init() {
  bindkey -M viins '^R' atuin-search-viins
  bindkey -M vicmd '^R' atuin-search
  bindkey -M vicmd '/' vi-history-search-backward
  bindkey -M viins '?' self-insert
  bindkey -M vicmd '?' vi-rev-repeat-search

  # Classic surround mode binds visual `ys<char>` as an alias for `S<char>`,
  # which makes `y` a prefix — so every visual yank stalls $ZVM_KEYTIMEOUT
  # (0.4s) waiting for a possible `s`. Drop the alias; `S` still adds surround.
  local s
  for s in '(' ')' '[' ']' '{' '}' '<' '>' "'" '"' '`' ' ' $'\e'; do
    bindkey -M visual -r "ys$s"
  done

  # Flash the yanked region, like LazyVim's highlight-on-yank. zvm_vi_yank is the
  # only caller of zvm_yank and the single entry point for every yank (visual
  # `y`, plus yy/yiw/y$ via the normal-mode default handler), so wrapping it
  # covers all of them and nothing else. The region is recomputed with the same
  # no-arg zvm_calc_selection that zvm_yank uses, before the yank runs, because
  # exiting visual mode resets CURSOR/MARK.
  functions[_zvm_vi_yank_orig]=$functions[zvm_vi_yank]
  zvm_vi_yank() {
    local ret=($(zvm_calc_selection))
    _zvm_vi_yank_orig "$@"
    _yank_flash $ret[1] $ret[2]
  }
}

# Yank flash, matching LazyVim's 150ms IncSearch (catppuccin sky on mantle).
autoload -Uz add-zle-hook-widget

# Re-applied on every redraw rather than set once: zsh-patina rebuilds
# region_highlight on line-pre-redraw, and later entries win, so appending ours
# last is what keeps the flash on top of patina's syntax colors.
_YANK_FLASH=()
_yank_flash_hook() {
  (( $#_YANK_FLASH )) && region_highlight+=("$_YANK_FLASH[1]")
}
add-zle-hook-widget line-pre-redraw _yank_flash_hook

# `zle -R` called directly from a `zle -F` handler returns 0 but never repaints;
# calling a registered widget from the handler does. Hence the indirection.
# The entry is also dropped explicitly, since `zle -R` repaints from whatever
# region_highlight already holds.
_yank_flash_redraw() {
  region_highlight=("${(@)region_highlight:#$1}")
  zle -R
}
zle -N _yank_flash_redraw

_yank_flash_end() {
  local fd=$1
  zle -F $fd
  exec {fd}<&-
  local entry=$_YANK_FLASH[1]
  _YANK_FLASH=()
  zle _yank_flash_redraw -- "$entry"
}

# The timer is a backgrounded sleep watched by `zle -F`, not an inline sleep, so
# the flash never blocks keyboard input.
_yank_flash() {
  local bpos=$1 epos=$2
  (( epos > bpos )) || return
  _YANK_FLASH=("$bpos $epos fg=$CAT_MANTLE,bg=$CAT_SKY")
  local fd
  exec {fd}< <(sleep 0.15)
  zle -F $fd _yank_flash_end
}

################################################################################
# Environment
################################################################################

export EDITOR="nvim"
export GIT_EDITOR="nvim"

################################################################################
# Tools (all use _cache_init to avoid fork-on-startup cost)
################################################################################

# Carapace — multi-shell completion engine
CARAPACE_BRIDGES='zsh,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
_cache_init carapace.zsh carapace _carapace

export EZA_ICONS_AUTO=always

_cache_init zoxide.zsh zoxide init zsh
_cache_init fzf.zsh fzf --zsh

# Atuin — shell history search on ^R. Must init AFTER fzf so its ^R binding
# wins over fzf-history-widget. --disable-up-arrow keeps zsh's up-arrow
# history. Atuin also grabs vicmd '/' and '?' (its AI prompt); those are
# restored in zvm_after_init above, which runs last and would overwrite
# anything bound here.
_cache_init atuin.zsh atuin init zsh --disable-up-arrow

# Bun completions — lazy-loaded because the file is ~1000 lines and only
# needed when you actually tab-complete a bun command.
if [[ -s "$HOME/.bun/_bun" ]]; then
  _bun_lazy() { unfunction _bun_lazy; source "$HOME/.bun/_bun"; _bun "$@"; }
  compdef _bun_lazy bun
fi

################################################################################
# Aliases
################################################################################

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

alias cl="clear"
alias rr='rm -f ~/.cache/zsh/*.zsh; source ~/.zshenv && source $ZDOTDIR/.zprofile && source $ZDOTDIR/.zshrc && rehash; true'
alias ls='eza --icons'
alias la='eza -la --icons --git'
alias lt='eza --tree --level=2 --icons'
alias v="nvim"
alias cat="bat"
alias cc="claude"
alias ta="tmux attach"
alias td="tmux detach"
alias tks="tmux kill-session"
alias tls="tmux list-sessions"

################################################################################
# Functions
################################################################################

source "$ZDOTDIR/jj.zsh" # jjw workspace helper

[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
