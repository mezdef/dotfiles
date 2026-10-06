# .zprofile — sourced for login shells only (before .zshrc).
# Sets up PATH, homebrew, and language toolchains.
# Machine-specific overrides go in .zprofile.local (git-ignored).
#
# Homebrew environment — hardcoded instead of `eval "$(brew shellenv)"` to avoid
# a ~40ms fork to the brew binary on every login shell start.
# Linux is Homebrew on Linux under WSL; .zshrc and tmux.conf read HOMEBREW_PREFIX.
if [[ $OSTYPE == darwin* ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
else
  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
fi
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
fpath[1,0]="$HOMEBREW_PREFIX/share/zsh/site-functions"
path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"

[[ -f "$ZDOTDIR/.zprofile.local" ]] && source "$ZDOTDIR/.zprofile.local"
