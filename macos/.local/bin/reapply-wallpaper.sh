#!/usr/bin/env bash
# reapply-wallpaper.sh — Re-apply the current wallpaper to all connected screens.
#
# Reads the wallpaper path from the wallpaper plist and sets it on every
# connected display via NSWorkspace. Does NOT pick a new random image.
#
# Triggered by launchd when display configuration changes (monitor connect/disconnect).
set -euo pipefail

swift -e '
import AppKit
import Foundation

let plistPath = NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
let plistURL = URL(fileURLWithPath: plistPath)

guard let plistData = try? Data(contentsOf: plistURL),
      let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
    fputs("Failed to read wallpaper plist\n", stderr)
    exit(1)
}

// Extract current wallpaper URL from SystemDefault or first display entry
func extractImageURL(from content: [String: Any]) -> URL? {
    guard let choices = content["Choices"] as? [[String: Any]],
          let first = choices.first,
          let configData = first["Configuration"] as? Data,
          let config = try? PropertyListSerialization.propertyList(from: configData, format: nil) as? [String: Any],
          let urlDict = config["url"] as? [String: Any],
          let relative = urlDict["relative"] as? String else { return nil }
    return URL(string: relative)
}

var imageURL: URL? = nil

// Try SystemDefault first
if let sysDefault = plist["SystemDefault"] as? [String: Any],
   let desktop = sysDefault["Desktop"] as? [String: Any],
   let content = desktop["Content"] as? [String: Any] {
    imageURL = extractImageURL(from: content)
}

// Fall back to first display entry
if imageURL == nil, let displays = plist["Displays"] as? [String: Any] {
    for (_, val) in displays {
        guard let d = val as? [String: Any],
              let desktop = d["Desktop"] as? [String: Any],
              let content = desktop["Content"] as? [String: Any] else { continue }
        if let url = extractImageURL(from: content) {
            imageURL = url
            break
        }
    }
}

guard let url = imageURL else {
    fputs("No wallpaper URL found in plist\n", stderr)
    exit(1)
}

let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    try ws.setDesktopImageURL(url, for: screen, options: [:])
}

print("Reapplied wallpaper: \(url.path)")
'
