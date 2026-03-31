// watch-keyboards.swift — Event-driven HID device watcher for kanata.
//
// Restarts kanata when external keyboards are connected or disconnected,
// so kanata can grab the new device and apply remappings.
//
// ## Why event-driven (not polling)
//
// Earlier versions polled `ioreg -r -c IOHIDDevice` every 5 seconds. This had
// problems: up to 5s delay before remappings applied, continuous CPU cost, and
// a blind spot after restart where devices connecting during cooldown were missed.
//
// This version uses IOKit's IOHIDManager which delivers attach/detach callbacks
// via CFRunLoop — instant reaction, zero idle CPU, no missed events.
//
// ## Why we match ALL HID devices (not just keyboards)
//
// Standard HID keyboards report PrimaryUsagePage=1 (Generic Desktop),
// PrimaryUsage=6 (Keyboard). We tried filtering on this but it fails for
// keyboards connected through USB docks/monitors. The dock's Realtek HID
// interface (which carries the keyboard) registers with vendor-specific usage
// pages (e.g. UsagePage=65498/0xFFDA) instead of the keyboard usage page.
// The actual keyboard (e.g. Mode M75H) does register correctly as UsagePage=1/
// Usage=6, but it appears as a separate device — and the dock's HID device
// appearing/disappearing is sometimes the only change signal.
//
// Tested keyboards:
//   - Mode 75 (M75H): USB via dock. Registers 3 HID interfaces: keyboard
//     (UsagePage=1/Usage=6), raw HID for VIA/VIAL (UsagePage=65376/Usage=97),
//     and a composite (system control + consumer + keyboard).
//   - ErgoDox EZ (early model, QMK Toolbox): USB via dock. Expected to register
//     as standard keyboard (UsagePage=1/Usage=6) based on QMK defaults.
//
// Note: Logitech G Pro mouse also exposes UsagePage=1/Usage=6 (for macro keys),
// so keyboard-only filtering would also false-trigger on mouse connect/disconnect.
//
// ## Exclusion strategy
//
// Instead of an allowlist (which misses non-standard keyboards), we use a denylist
// of known static/non-keyboard devices that never change during normal use:
//   - Apple built-in (manufacturer "Apple" or "APPL"): internal keyboard, trackpad, sensors
//   - Karabiner virtual HID (manufacturer "pqrs.org"): always present when driver loaded
//   - BTM (Bluetooth Manager): system service, not a keyboard
//   - Keyboard Backlight: Apple internal backlight control, not a keyboard
//
// Any other HID device change triggers a kanata restart. This catches keyboards
// regardless of how they identify themselves or what they're connected through.

import Foundation
import IOKit
import IOKit.hid

let cooldownSeconds: TimeInterval = 10
let maxRetries = 3
let retryDelay: UInt32 = 3

var lastRestart = Date.distantPast

func log(_ message: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("[\(ts)] \(message)")
    fflush(stdout)
}

func shouldIgnore(_ device: IOHIDDevice) -> Bool {
    let product = IOHIDDeviceGetProperty(device, "Product" as CFString) as? String ?? ""
    let manufacturer = IOHIDDeviceGetProperty(device, "Manufacturer" as CFString) as? String ?? ""

    // Apple built-in devices (keyboard, trackpad, sensors)
    if manufacturer == "Apple" || manufacturer == "APPL" { return true }
    // Karabiner virtual keyboard
    if manufacturer == "pqrs.org" || product.contains("Karabiner") { return true }
    // Known non-keyboard peripherals
    if product == "BTM" || product == "Keyboard Backlight" { return true }

    return false
}

func restartKanata(reason: String) {
    let now = Date()
    if now.timeIntervalSince(lastRestart) < cooldownSeconds {
        log("Cooldown active, skipping restart for: \(reason)")
        return
    }
    lastRestart = now

    log("HID device change: \(reason)")

    for attempt in 1...maxRetries {
        log("Restarting kanata (attempt \(attempt)/\(maxRetries))")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["kickstart", "-k", "system/com.jtroo.kanata"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log("Failed to run launchctl: \(error.localizedDescription)")
            if attempt < maxRetries { sleep(retryDelay) }
            continue
        }

        if process.terminationStatus == 0 {
            // Verify kanata is running
            sleep(retryDelay)
            let check = Process()
            check.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            check.arguments = ["print", "system/com.jtroo.kanata"]
            let pipe = Pipe()
            check.standardOutput = pipe
            check.standardError = FileHandle.nullDevice
            do {
                try check.run()
                check.waitUntilExit()
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                if output.contains("state = running") {
                    log("Kanata restarted successfully")
                    return
                }
            } catch {
                // Verification failed, but kickstart succeeded — probably fine
                log("Kanata restart issued (could not verify state)")
                return
            }
        }

        log("Attempt \(attempt) failed (exit \(process.terminationStatus))")
        if attempt < maxRetries { sleep(retryDelay) }
    }

    log("Kanata failed to restart after \(maxRetries) attempts")
}

// Callbacks
let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
    if shouldIgnore(device) { return }
    let product = IOHIDDeviceGetProperty(device, "Product" as CFString) as? String ?? "unknown"
    let manufacturer = IOHIDDeviceGetProperty(device, "Manufacturer" as CFString) as? String ?? "unknown"
    restartKanata(reason: "attached \(product) (\(manufacturer))")
}

let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
    if shouldIgnore(device) { return }
    let product = IOHIDDeviceGetProperty(device, "Product" as CFString) as? String ?? "unknown"
    let manufacturer = IOHIDDeviceGetProperty(device, "Manufacturer" as CFString) as? String ?? "unknown"
    restartKanata(reason: "detached \(product) (\(manufacturer))")
}

// Set up HID Manager
let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

// Match all HID devices — we filter in the callbacks
IOHIDManagerSetDeviceMatching(manager, nil)
IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, nil)
IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if openResult != kIOReturnSuccess {
    log("Error: failed to open IOHIDManager (0x\(String(openResult, radix: 16)))")
    exit(1)
}

log("Watching for HID device changes...")

// Run forever
CFRunLoopRun()
