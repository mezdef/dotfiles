# .zprofile — sourced for login shells only (before .zshrc).
# Sets up PATH, homebrew, and language toolchains.
# Machine-specific overrides go in .zprofile.local (git-ignored).
#
# Homebrew environment — hardcoded instead of `eval "$(brew shellenv)"` to avoid
# a ~40ms fork to the brew binary on every login shell start.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"

[[ -f "$ZDOTDIR/.zprofile.local" ]] && source "$ZDOTDIR/.zprofile.local"
