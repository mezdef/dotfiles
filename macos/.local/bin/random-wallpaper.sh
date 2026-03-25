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

# Use Swift to set wallpaper on connected screens via NSWorkspace AND update the
# wallpaper plist for ALL known displays (including disconnected monitors).
# NSWorkspace alone only affects connected screens — disconnected monitors read
# from ~/Library/Application Support/com.apple.wallpaper/Store/Index.plist.
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

// 1. Set connected screens immediately via NSWorkspace
let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    try ws.setDesktopImageURL(picked, for: screen, options: [:])
}

// Wait for wallpaper agent to finish writing its plist update from NSWorkspace
Thread.sleep(forTimeInterval: 1.0)

// 2. Update the wallpaper plist for ALL displays (including disconnected)
let plistPath = NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
let plistURL = URL(fileURLWithPath: plistPath)

if let plistData = try? Data(contentsOf: plistURL),
   var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {

    // Build Configuration binary plist for the new image
    let config: [String: Any] = [
        "type": "imageFile",
        "url": ["relative": "file://" + picked.path]
    ]
    let configData = try PropertyListSerialization.data(fromPropertyList: config, format: .binary, options: 0)

    // Find existing EncodedOptionValues (placement/color settings) to preserve
    func findOptions(in plist: [String: Any]) -> Data? {
        guard let displays = plist["Displays"] as? [String: Any] else { return nil }
        for (_, val) in displays {
            guard let d = val as? [String: Any],
                  let desktop = d["Desktop"] as? [String: Any],
                  let content = desktop["Content"] as? [String: Any],
                  let opts = content["EncodedOptionValues"] as? Data,
                  opts.count > 0 else { continue }
            return opts
        }
        return nil
    }
    let options = findOptions(in: plist)

    // Replace Desktop wallpaper in a Content dict
    func updateContent(_ content: inout [String: Any]) {
        guard var choices = content["Choices"] as? [[String: Any]], !choices.isEmpty else { return }
        choices[0]["Configuration"] = configData
        choices[0]["Provider"] = "com.apple.wallpaper.choice.image"
        content["Choices"] = choices
        if let options { content["EncodedOptionValues"] = options }
    }

    // Update Displays
    if var displays = plist["Displays"] as? [String: Any] {
        for (uuid, val) in displays {
            guard var d = val as? [String: Any],
                  var desktop = d["Desktop"] as? [String: Any],
                  var content = desktop["Content"] as? [String: Any] else { continue }
            updateContent(&content)
            desktop["Content"] = content; d["Desktop"] = desktop; displays[uuid] = d
        }
        plist["Displays"] = displays
    }

    // Update Spaces (per-space default + per-space per-display)
    if var spaces = plist["Spaces"] as? [String: Any] {
        for (spaceUUID, spaceVal) in spaces {
            guard var space = spaceVal as? [String: Any] else { continue }
            if var def = space["Default"] as? [String: Any],
               var desktop = def["Desktop"] as? [String: Any],
               var content = desktop["Content"] as? [String: Any] {
                updateContent(&content)
                desktop["Content"] = content; def["Desktop"] = desktop; space["Default"] = def
            }
            if var spaceDisplays = space["Displays"] as? [String: Any] {
                for (dUUID, dVal) in spaceDisplays {
                    guard var d = dVal as? [String: Any],
                          var desktop = d["Desktop"] as? [String: Any],
                          var content = desktop["Content"] as? [String: Any] else { continue }
                    updateContent(&content)
                    desktop["Content"] = content; d["Desktop"] = desktop; spaceDisplays[dUUID] = d
                }
                space["Displays"] = spaceDisplays
            }
            spaces[spaceUUID] = space
        }
        plist["Spaces"] = spaces
    }

    // Update SystemDefault
    if var sysDefault = plist["SystemDefault"] as? [String: Any],
       var desktop = sysDefault["Desktop"] as? [String: Any],
       var content = desktop["Content"] as? [String: Any] {
        updateContent(&content)
        desktop["Content"] = content; sysDefault["Desktop"] = desktop
        plist["SystemDefault"] = sysDefault
    }

    let outData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
    try outData.write(to: plistURL, options: .atomic)
}

print(picked.path)
')

echo "$(date '+%Y-%m-%d %H:%M:%S') Setting wallpaper: $wallpaper"
