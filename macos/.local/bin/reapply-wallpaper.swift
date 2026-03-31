// reapply-wallpaper.swift — Re-apply current wallpaper to all connected screens.
//
// Called by reapply-wallpaper.sh when launchd detects a display configuration change
// (monitor connect/disconnect via WatchPaths on com.apple.windowserver.displays.plist).
//
// Problem: when a monitor reconnects, macOS wallpaper agent may revert it to whatever
// wallpaper was last associated with that display UUID in the plist — not necessarily
// the one we set with random-wallpaper.sh.
//
// Solution: read our desired wallpaper from SystemDefault (or first Displays entry),
// then update all Displays AND Spaces entries to match, and call NSWorkspace to
// apply immediately on connected screens.
//
// Spaces support: both the per-space Default and per-space-per-display entries are
// updated. Without this, switching to a different Space on a newly connected monitor
// could show a stale wallpaper.

import AppKit
import Foundation

let plistPath = NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
let plistURL = URL(fileURLWithPath: plistPath)

guard let plistData = try? Data(contentsOf: plistURL),
      var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
    fputs("Error: failed to read wallpaper plist\n", stderr)
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
    fputs("Error: no wallpaper URL found in plist\n", stderr)
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

// Update Spaces (per-space default + per-space per-display)
if var spaces = plist["Spaces"] as? [String: Any] {
    for (spaceUUID, spaceVal) in spaces {
        guard var space = spaceVal as? [String: Any] else { continue }
        if var def = space["Default"] as? [String: Any],
           var desktop = def["Desktop"] as? [String: Any],
           var content = desktop["Content"] as? [String: Any] {
            let existingURL = extractImageURL(from: content)
            if existingURL != url {
                content = templateContent
                desktop["Content"] = content; def["Desktop"] = desktop; space["Default"] = def
                plistChanged = true
            }
        }
        if var spaceDisplays = space["Displays"] as? [String: Any] {
            for (dUUID, dVal) in spaceDisplays {
                guard var d = dVal as? [String: Any],
                      var desktop = d["Desktop"] as? [String: Any],
                      var content = desktop["Content"] as? [String: Any] else { continue }
                let existingURL = extractImageURL(from: content)
                if existingURL != url {
                    content = templateContent
                    desktop["Content"] = content; d["Desktop"] = desktop; spaceDisplays[dUUID] = d
                    plistChanged = true
                }
            }
            space["Displays"] = spaceDisplays
        }
        spaces[spaceUUID] = space
    }
    if plistChanged { plist["Spaces"] = spaces }
}

if plistChanged {
    do {
        let outData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        try outData.write(to: plistURL, options: .atomic)
    } catch {
        fputs("Error: failed to write wallpaper plist: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

// Now set via NSWorkspace — this takes effect immediately on connected screens
let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    do {
        try ws.setDesktopImageURL(url, for: screen, options: [:])
    } catch {
        fputs("Warning: failed to set wallpaper for screen: \(error.localizedDescription)\n", stderr)
    }
}

print("Reapplied wallpaper: \(url.path)")
