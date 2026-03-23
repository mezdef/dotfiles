#!/usr/bin/env bash
# random-wallpaper.sh — Pick a random wallpaper and apply it to all desktops.
#
# Usage:
#   random-wallpaper.sh [wallpaper_dir]
#
# Arguments:
#   wallpaper_dir  Path to folder of images (default: ~/Library/CloudStorage/Dropbox/Resorces/wallpaper)
#
# Supported formats: jpg, jpeg, png, heic, webp
#
# Scheduled via launchd (com.marc.randomwallpaper.plist).
# Logs to ~/Library/Logs/random-wallpaper.log when run by launchd.
#
# Deploy:
#   cd ~/dotfiles && stow macos
#   launchctl load ~/Library/LaunchAgents/com.marc.randomwallpaper.plist
#
# Manage:
#   launchctl list | grep randomwallpaper   # check if loaded
#   launchctl unload ~/Library/LaunchAgents/com.marc.randomwallpaper.plist  # stop
set -euo pipefail

WALLPAPER_DIR="${1:-$HOME/Library/CloudStorage/Dropbox/Resorces/wallpaper}"

# Wait for Dropbox CloudStorage to mount (up to 2 minutes)
retries=24
while [[ ! -d "$WALLPAPER_DIR" && $retries -gt 0 ]]; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') Waiting for $WALLPAPER_DIR to mount..."
  sleep 5
  ((retries--))
done

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "Error: directory not found after waiting: $WALLPAPER_DIR" >&2
  exit 1
fi

# Use Swift with NSWorkspace API to set wallpaper on ALL screens — this writes
# to the macOS desktop picture database so new monitors pick it up too.
# Swift also has full access to File Provider (CloudStorage) paths from launchd.
wallpaper=$(WALLPAPER_DIR="$WALLPAPER_DIR" swift -e '
import AppKit
import Foundation

let dir = ProcessInfo.processInfo.environment["WALLPAPER_DIR"]!
let url = URL(fileURLWithPath: dir)
let exts: Set = ["jpg", "jpeg", "png", "heic", "webp"]
let files = try FileManager.default
    .contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    .filter { exts.contains($0.pathExtension.lowercased()) }

guard !files.isEmpty else { fputs("no image files found\n", stderr); exit(1) }

let picked = files[Int.random(in: 0..<files.count)]
let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    try ws.setDesktopImageURL(picked, for: screen, options: [:])
}
print(picked.path)
')

echo "$(date '+%Y-%m-%d %H:%M:%S') Setting wallpaper: $wallpaper"
