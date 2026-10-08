#!/bin/bash
# Installs tools and stows every package for this OS. Safe to rerun on an existing machine.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v brew >/dev/null; then
  echo "setup: install Homebrew first, see README.md" >&2
  exit 1
fi

# An upgrade drops kanata's Input Monitoring grant and it doubles every keypress; see kanata/README.md.
# Pinned before bundle so it is never upgraded, and after so a fresh install is pinned too.
pin_kanata() {
  if [[ "$(uname)" == Darwin ]] && brew list --versions kanata >/dev/null && ! brew list --pinned | grep -qx kanata; then
    brew pin kanata
  fi
}

pin_kanata
brew bundle
pin_kanata

# A directory missing at stow time becomes a symlink into the repo, so create the ones apps write to.
mkdir -p ~/.config/jj ~/.local/bin ~/.local/share
stow atuin bat jjui nvim zsh
# Real directories, so another repo can add files beside these; -R unfolds an old folded link.
stow -R --no-folding git jj tmux herdr

if [[ "$(uname)" == Darwin ]]; then
  stow ghostty kanata macos
  # Karabiner replaces the link with a file on save; an existing file already skips its setup prompt.
  [[ -e ~/.config/karabiner/karabiner.json ]] || stow karabiner
  # Laptop only: its gitignored env opts in, and the mini's never does.
  if grep -qx 'FILESYNC_CLIENT=1' syncthing/.config/filesync/env 2>/dev/null; then
    stow syncthing
  fi
fi

if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi
~/.config/tmux/plugins/tpm/bin/install_plugins

echo "setup: done; see README.md for the manual steps"
