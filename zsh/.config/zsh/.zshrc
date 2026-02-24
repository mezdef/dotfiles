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

# Plugins
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

# Catppuccin mocha colors (for cursor)
CATPPUCCIN_TEXT="#cdd6f4"
CATPPUCCIN_GREEN="#a6e3a1"

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne "\e[1 q\e]12;${CATPPUCCIN_GREEN}\a"  # block, blue (normal mode)
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne "\e[1 q\e]12;${CATPPUCCIN_TEXT}\a"  # block, white (insert mode)
  fi
  zle reset-prompt
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[1 q\e]12;${CATPPUCCIN_TEXT}\a"
}
zle -N zle-line-init
echo -ne "\e[1 q\e]12;${CATPPUCCIN_TEXT}\a" # Block cursor, white on startup.
preexec() { echo -ne '\e[1 q\e]12;${CATPPUCCIN_TEXT}\a' ;} # Reset to insert mode cursor before each command.

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

