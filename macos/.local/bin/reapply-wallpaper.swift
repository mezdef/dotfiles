// reapply-wallpaper.swift — Re-apply current wallpaper to all connected screens.
//
// Called by reapply-wallpaper.sh when launchd detects a display configuration change
// (monitor connect/disconnect via WatchPaths on com.apple.windowserver.displays.plist).
//
// Problem: when a monitor reconnects, macOS wallpaper agent may revert it to whatever
// wallpaper was last associated with that display UUID in the plist — not necessarily
// the one we set with random-wallpaper.sh.
//
// Solution: read our desired wallpaper from a sidecar file (~/.local/state/current-wallpaper)
// written by random-wallpaper.swift, then update all Displays, Spaces, and SystemDefault
// entries to match, and call NSWorkspace to apply immediately on connected screens.
// Falls back to reading from plist if sidecar doesn't exist yet.
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

// Find the desired wallpaper — prefer sidecar file (immune to macOS plist overwrites)
var imageURL: URL? = nil

let sidecarPath = NSHomeDirectory() + "/.local/state/current-wallpaper"
if let path = try? String(contentsOfFile: sidecarPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
   FileManager.default.fileExists(atPath: path) {
    imageURL = URL(fileURLWithPath: path)
}

// Fallback: read from plist (before sidecar exists)
if imageURL == nil {
    if let sysDefault = plist["SystemDefault"] as? [String: Any],
       let desktop = sysDefault["Desktop"] as? [String: Any],
       let content = desktop["Content"] as? [String: Any] {
        imageURL = extractImageURL(from: content)
    }
    if imageURL == nil,
       let displays = plist["Displays"] as? [String: Any] {
        for (_, val) in displays {
            guard let d = val as? [String: Any],
                  let desktop = d["Desktop"] as? [String: Any],
                  let content = desktop["Content"] as? [String: Any] else { continue }
            if let u = extractImageURL(from: content) {
                imageURL = u
                break
            }
        }
    }
}

guard let url = imageURL else {
    fputs("Error: no wallpaper URL found in sidecar or plist\n", stderr)
    exit(1)
}

// Build Configuration binary plist for the desired image
let config: [String: Any] = [
    "type": "imageFile",
    "url": ["relative": "file://" + url.path]
]
let configData = try PropertyListSerialization.data(fromPropertyList: config, format: .binary, options: 0)

// Update Choices[0] in a Content dict to point to our wallpaper
func updateContent(_ content: inout [String: Any]) {
    guard var choices = content["Choices"] as? [[String: Any]], !choices.isEmpty else { return }
    choices[0]["Configuration"] = configData
    choices[0]["Provider"] = "com.apple.wallpaper.choice.image"
    content["Choices"] = choices
}

// Update all display entries in the plist to use the same wallpaper.
// This ensures newly connected monitors get the right Content, so macOS
// wallpaper agent does not revert them to a stale default.
var plistChanged = false

if var displays = plist["Displays"] as? [String: Any] {
    for (uuid, val) in displays {
        guard var d = val as? [String: Any],
              var desktop = d["Desktop"] as? [String: Any],
              var content = desktop["Content"] as? [String: Any] else { continue }
        let existingURL = extractImageURL(from: content)
        if existingURL != url {
            updateContent(&content)
            desktop["Content"] = content; d["Desktop"] = desktop; displays[uuid] = d
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
                updateContent(&content)
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
                    updateContent(&content)
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

// Update SystemDefault
if var sysDefault = plist["SystemDefault"] as? [String: Any],
   var desktop = sysDefault["Desktop"] as? [String: Any],
   var content = desktop["Content"] as? [String: Any] {
    let existingURL = extractImageURL(from: content)
    if existingURL != url {
        updateContent(&content)
        desktop["Content"] = content; sysDefault["Desktop"] = desktop
        plist["SystemDefault"] = sysDefault
        plistChanged = true
    }
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
