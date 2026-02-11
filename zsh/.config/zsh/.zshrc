################################################################################
# Misc
################################################################################

# History
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

autoload -U compinit && compinit

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/share/lsd/lsd.plugin.zsh

################################################################################
# Terminal Theme
################################################################################

# Starship
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

################################################################################
# VIM Settings for Terminal
################################################################################

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

################################################################################
# Git
################################################################################

export EDITOR="nvim"
export GIT_EDITOR="nvim"

################################################################################
# Libraries
################################################################################

# Carapace
CARAPACE_BRIDGES='zsh,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# Zoxide - Better CD
eval "$(zoxide init zsh)"

# fzf - key bindings and fuzzy completion
source <(fzf --zsh)

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
# bun completions
[ -s "/Users/marc.deferranti/.bun/_bun" ] && source "/Users/marc.deferranti/.bun/_bun"

################################################################################
# Aliases
################################################################################

# Dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

alias cl="clear"
alias rr='source ~/.config/zsh/.zshrc && rehash && compinit'
alias ls="lsd -la"
alias v="nvim"

