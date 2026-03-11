eval "$(/opt/homebrew/bin/brew shellenv)"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"

[[ -f "$ZDOTDIR/.zprofile.local" ]] && source "$ZDOTDIR/.zprofile.local"
