# Path /////////////////////////////////////////////////////////////////////////

# Homebrew path
PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# RVM path for scripting
PATH=$PATH:$HOME/.rvm/bin

# PATH Python
export PYTHONPATH="$PYTHONPATH:/usr/local/Cellar/python/2.7.3/lib/python2.7/site-packages"

# ZSH function path
fpath=(/usr/local/share/zsh-completions $fpath)

# RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

if [ -d ~/.local/bin ]; then export PATH=~/.local/bin:$PATH ; fi


# General options //////////////////////////////////////////////////////////////

setopt prompt_subst
autoload -U colors && colors # Enable colors in prompt
autoload -U compinit
compinit

setopt autocd
setopt AUTO_NAME_DIRS
setopt VI
# Set VI mode for zsh
bindkey -v
# bindkey -M viins 'jj' vi-cmd-mode
setopt NO_CASE_GLOB

# CLI Editor
export EDITOR="vim"
export VISUAL="vim"

# Prompt ///////////////////////////////////////////////////////////////////////

# Left hand prompt
PROMPT='$ '
# Right hand prompt
RPROMPT='%F%*%f'


# ZSH Autocompletion ///////////////////////////////////////////////////////////

bindkey -M viins '\C-i' complete-word

# Faster! (?)
zstyle ':completion::complete:*' use-cache 1

# case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''
#zstyle ':completion:*' completer _oldlist _expand _complete
zstyle ':completion:*' completer _expand _complete _approximate _ignored

# generate descriptions with magic.
zstyle ':completion:*' auto-description 'specify: %d'

# Don't prompt for a huge list, page it!
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Don't prompt for a huge list, menu it!
zstyle ':completion:*:default' menu 'select=0'

# Have the newer files last so I see them first
zstyle ':completion:*' file-sort modification reverse

# color code completion!!!!  Wohoo!
zstyle ':completion:*' list-colors "=(#b) #([0-9]#)*=36=31"

unsetopt LIST_AMBIGUOUS
setopt  COMPLETE_IN_WORD


# ZSH History //////////////////////////////////////////////////////////////////

# Where it gets saved
HISTFILE=~/Dropbox/Settings/dotfiles/.zsh_history

# Remember about a years worth of history (AWESOME)
SAVEHIST=100000
HISTSIZE=100000

# Don't overwrite, append!
setopt APPEND_HISTORY

# Killer: share history between multiple shells
setopt SHARE_HISTORY
# If I type cd and then cd again, only save the last one
setopt HIST_IGNORE_DUPS
# Even if there are commands inbetween commands that are the same, still only save the last one
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE # If a line starts with a space, don't save it.
setopt HIST_NO_STORE

# When using a hist thing, make a newline show the change before executing it.
setopt HIST_VERIFY

# Save the time and how long a command ran
setopt EXTENDED_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# Bind Up and Down to search backwards / forwards after typing
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward


# Aliases //////////////////////////////////////////////////////////////////////

# Aliases - Config
# alias mvim="open -a MacVim"
# alias zshrc="vim ~/dotfiles/zsh/zshrc"
# alias vimrc="vim ~/dotfiles/vim/vimrc"

# Aliases - Editor
# MacVim as terminal vim
#alias vim="/Users/mezdef/Applications/MacVim.app/Contents/MacOS/Vim"

# Aliases - Git
# alias g="git"

# Aliases - Rails
# alias dbsetup="rake db:create db:migrate db:seed db:populate db:test:prepare"

# Aliases - Shell navigation
alias cl="clear"
alias k='tree'
alias ltr='ls -ltr'
alias r='screen -D -R'
alias ls='ls -Ga'
alias l='ls -lh'
alias ll='ls -la'

# Plugins //////////////////////////////////////////////////////////////////////

# Syntax highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# History search
source /usr/local/Cellar/zsh-history-substring-search/1.0.0/zsh-history-substring-search.zsh
