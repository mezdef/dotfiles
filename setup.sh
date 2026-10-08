#!/bin/bash
# Installs tools and stows every package for this OS. Safe to rerun on an existing machine.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v brew >/dev/null; then
  echo "setup: install Homebrew first, see README.md" >&2
  exit 1
fi

brew bundle

# A directory missing at stow time becomes a symlink into the repo, so create the ones apps write to.
mkdir -p ~/.config/jj ~/.local/bin ~/.local/share
stow atuin bat git herdr jj jjui nvim tmux zsh

if [[ "$(uname)" == Darwin ]]; then
  stow ghostty kanata macos swiftbar
  # Karabiner replaces the link with a file on save; an existing file already skips its setup prompt.
  [[ -e ~/.config/karabiner/karabiner.json ]] || stow karabiner
  launchagents=(macos/Library/LaunchAgents/*.plist)
  # Laptop only: its gitignored env opts in, and the mini's never does.
  if grep -qx 'FILESYNC_CLIENT=1' syncthing/.config/filesync/env 2>/dev/null; then
    stow syncthing
    launchagents+=(syncthing/Library/LaunchAgents/*.plist)
  fi
  macos/.local/bin/install-launchagent "${launchagents[@]}"
fi

if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi
~/.config/tmux/plugins/tpm/bin/install_plugins

echo "setup: done; see README.md for the manual steps"
