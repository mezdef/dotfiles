# .zshenv — sourced for ALL zsh sessions (login, interactive, scripts).
# Keep this minimal: only set ZDOTDIR to redirect config loading.
#
# Zsh load order:
#   .zshenv → .zprofile (login) → .zshrc (interactive) → .zlogin (login)
#
# Config files live in $ZDOTDIR (~/.config/zsh/):
#   .zprofile       Homebrew env, PATH setup (login shells)
#   .zprofile.local Machine-specific env vars, secrets (not in dotfiles repo)
#   .zshrc          Main interactive config: plugins, prompt, aliases, tools
#   .zshrc.local    Machine-specific interactive overrides (not in dotfiles repo)
#   theme.zsh       Catppuccin Mocha color palette
#   prompt.zsh      Pure zsh prompt + vi mode cursor colors
#   jj.zsh          Jujutsu VCS shell utilities

export ZDOTDIR="$HOME/.config/zsh"
