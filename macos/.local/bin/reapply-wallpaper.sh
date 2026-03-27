#!/usr/bin/env bash
# reapply-wallpaper.sh — Re-apply the current wallpaper to all connected screens.
#
# Reads the wallpaper path from the wallpaper plist and sets it on every
# connected display via NSWorkspace. Also updates the plist for any new
# display UUIDs so macOS's wallpaper agent doesn't revert them.
#
# Triggered by launchd when display configuration changes (monitor connect/disconnect).
set -euo pipefail

# Let macOS wallpaper agent finish its own setup before we override
sleep 3

swift -e '
import AppKit
import Foundation

let plistPath = NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
let plistURL = URL(fileURLWithPath: plistPath)

guard let plistData = try? Data(contentsOf: plistURL),
      var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
    fputs("Failed to read wallpaper plist\n", stderr)
    exit(1)
}

// Extract current wallpaper URL from a Content dict
func extractImageURL(from content: [String: Any]) -> URL? {
    guard let choices = content["Choices"] as? [[String: Any]],
          let first = choices.first,
          let configData = first["Configuration"] as? Data,
          let config = try? PropertyListSerialization.propertyList(from: configData, format: nil) as? [String: Any],
          let urlDict = config["url"] as? [String: Any],
          let relative = urlDict["relative"] as? String else { return nil }
    return URL(string: relative)
}

// Find the desired wallpaper from SystemDefault or first display entry
var imageURL: URL? = nil
var sourceContent: [String: Any]? = nil

if let sysDefault = plist["SystemDefault"] as? [String: Any],
   let desktop = sysDefault["Desktop"] as? [String: Any],
   let content = desktop["Content"] as? [String: Any] {
    imageURL = extractImageURL(from: content)
    sourceContent = content
}

if imageURL == nil || sourceContent == nil,
   let displays = plist["Displays"] as? [String: Any] {
    for (_, val) in displays {
        guard let d = val as? [String: Any],
              let desktop = d["Desktop"] as? [String: Any],
              let content = desktop["Content"] as? [String: Any] else { continue }
        if let url = extractImageURL(from: content) {
            imageURL = url
            if sourceContent == nil { sourceContent = content }
            break
        }
    }
}

guard let url = imageURL, let templateContent = sourceContent else {
    fputs("No wallpaper URL found in plist\n", stderr)
    exit(1)
}

// Update all display entries in the plist to use the same wallpaper.
// This ensures newly connected monitors get the right Content, so macOS
// wallpaper agent does not revert them to a stale default.
var plistChanged = false

if var displays = plist["Displays"] as? [String: Any] {
    for (uuid, val) in displays {
        guard var d = val as? [String: Any],
              var desktop = d["Desktop"] as? [String: Any] else { continue }
        let existing = desktop["Content"] as? [String: Any]
        let existingURL = existing.flatMap { extractImageURL(from: $0) }
        if existingURL != url {
            desktop["Content"] = templateContent
            d["Desktop"] = desktop
            displays[uuid] = d
            plistChanged = true
        }
    }
    if plistChanged { plist["Displays"] = displays }
}

if plistChanged {
    let outData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
    try outData.write(to: plistURL, options: .atomic)
}

// Now set via NSWorkspace — this takes effect immediately on connected screens
let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    try ws.setDesktopImageURL(url, for: screen, options: [:])
}

print("Reapplied wallpaper: \(url.path)")
'
