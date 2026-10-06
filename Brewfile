# Tools the stow packages call. `brew bundle` from the repo root.

tap "dlvhdr/formulae"

brew "stow"
brew "git-delta"
brew "dlvhdr/formulae/diffnav"
brew "jj"
brew "jjui"
brew "neovim"
brew "ripgrep"
brew "fd"
brew "tmux"
brew "herdr"
brew "bat"
brew "atuin"
brew "carapace"
brew "eza"
brew "fzf"
brew "zoxide"
brew "zsh-autosuggestions"
brew "zsh-vi-mode"
brew "zsh-patina"

# macOS ships zsh, git and jq in /usr/bin
if OS.linux?
  brew "zsh"
  brew "git"
  brew "jq"
end

if OS.mac?
  brew "kanata"
  cask "karabiner-elements"
  cask "ghostty"
  cask "claude-code"
  cask "font-jetbrains-mono-nerd-font"
end
