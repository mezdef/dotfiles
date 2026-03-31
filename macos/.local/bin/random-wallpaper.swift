// random-wallpaper.swift — Pick a random image and set it on all desktops.
//
// Called by random-wallpaper.sh, which handles the Dropbox mount wait.
// Receives WALLPAPER_DIR via environment variable.
//
// Two-phase approach:
//   1. NSWorkspace.setDesktopImageURL — sets wallpaper on currently connected screens.
//      This is the only public API, but it only affects screens macOS can see right now.
//   2. Direct plist patching — updates ~/Library/Application Support/com.apple.wallpaper/
//      Store/Index.plist so disconnected monitors, other Spaces, and SystemDefault all
//      get the new image. Without this, reconnecting a monitor reverts to its old wallpaper.
//
// The plist has three sections we update:
//   - Displays: per-display-UUID wallpaper (including UUIDs for disconnected monitors)
//   - Spaces: per-Space defaults and per-Space-per-display overrides
//   - SystemDefault: fallback for any new display that has no entry yet
//
// We preserve EncodedOptionValues (scaling/placement settings) from existing entries
// so the wallpaper appearance stays consistent.

import AppKit
import Foundation

let dir = ProcessInfo.processInfo.environment["WALLPAPER_DIR"]!
let url = URL(fileURLWithPath: dir)
let exts: Set = ["jpg", "jpeg", "png", "heic", "webp"]
let files = try FileManager.default
    .contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    .filter { exts.contains($0.pathExtension.lowercased()) }

guard !files.isEmpty else {
    fputs("Error: no image files found in \(dir)\n", stderr)
    exit(1)
}

let picked = files[Int.random(in: 0..<files.count)]

// 1. Set connected screens immediately via NSWorkspace
let ws = NSWorkspace.shared
for screen in NSScreen.screens {
    do {
        try ws.setDesktopImageURL(picked, for: screen, options: [:])
    } catch {
        fputs("Warning: failed to set wallpaper for screen: \(error.localizedDescription)\n", stderr)
    }
}

// Wait for macOS wallpaper agent to flush its plist after NSWorkspace call.
// NSWorkspace triggers an async write by the system wallpaper agent — if we read
// the plist too soon we get stale data and our edits get overwritten.
// 1s is empirically sufficient; shorter sleeps caused intermittent overwrites.
Thread.sleep(forTimeInterval: 1.0)

// 2. Update the wallpaper plist for ALL displays (including disconnected)
let plistPath = NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
let plistURL = URL(fileURLWithPath: plistPath)

guard let plistData = try? Data(contentsOf: plistURL),
      var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
    fputs("Warning: could not read wallpaper plist, skipping plist update\n", stderr)
    // Still print the picked path — NSWorkspace already set connected screens
    print(picked.path)
    exit(0)
}

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

do {
    let outData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
    try outData.write(to: plistURL, options: .atomic)
} catch {
    fputs("Warning: failed to write wallpaper plist: \(error.localizedDescription)\n", stderr)
}

print(picked.path)
