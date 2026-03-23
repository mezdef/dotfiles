#!/usr/bin/env bash
# Build karabiner.ts → karabiner/.config/karabiner/karabiner.json, then stow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
KARABINER_TS_DIR="$DOTFILES_DIR/karabiner-ts"

echo "Building karabiner config..."
cd "$KARABINER_TS_DIR"
npm run build

echo "Stowing karabiner config..."
cd "$DOTFILES_DIR"
stow --adopt karabiner

echo "Done. Karabiner-Elements will auto-reload."
