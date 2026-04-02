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
