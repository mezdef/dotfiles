// watch-keyboards.swift — Event-driven USB device watcher for kanata.
//
// Restarts kanata when external USB devices are connected or disconnected,
// so kanata can grab new keyboards and apply remappings.
//
// Uses IOKit service notifications (IOServiceAddMatchingNotification) to watch
// for IOUSBHostDevice changes. This does NOT require Input Monitoring / TCC
// permissions — it observes the IOKit registry, not HID device streams.
//
// When a non-ignored device appears or disappears, touches /tmp/kanata-restart-trigger.
// The kanata-restarter LaunchDaemon (root) watches that file and restarts kanata.

import Foundation
import IOKit
import IOKit.usb

let cooldownSeconds: TimeInterval = 10
var lastRestart = Date.distantPast
var notifyPortRef: IONotificationPortRef?

func log(_ message: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("[\(ts)] \(message)")
    fflush(stdout)
}

func deviceName(_ service: io_service_t) -> String {
    var name = [CChar](repeating: 0, count: 128)
    IORegistryEntryGetName(service, &name)
    return String(cString: name)
}

func deviceProduct(_ service: io_service_t) -> String {
    if let cf = IORegistryEntryCreateCFProperty(service, "USB Product Name" as CFString, kCFAllocatorDefault, 0) {
        return cf.takeRetainedValue() as? String ?? "unknown"
    }
    return deviceName(service)
}

func shouldIgnore(_ service: io_service_t) -> Bool {
    let product = deviceProduct(service)
    let name = deviceName(service)
    // Apple internal devices
    if product.hasPrefix("Apple") || name.hasPrefix("Apple") { return true }
    // Karabiner virtual HID
    if product.contains("Karabiner") || product.contains("pqrs") { return true }
    return false
}

func requestKanataRestart(reason: String) {
    let now = Date()
    if now.timeIntervalSince(lastRestart) < cooldownSeconds {
        log("Cooldown active, skipping restart for: \(reason)")
        return
    }
    lastRestart = now
    log("USB device change: \(reason)")
    let triggerPath = "/tmp/kanata-restart-trigger"
    FileManager.default.createFile(atPath: triggerPath, contents: nil)
    log("Wrote restart trigger")
}

// Drain an iterator, optionally triggering restart for non-ignored devices
func drainIterator(_ iterator: io_iterator_t, event: String, trigger: Bool) {
    while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
        let product = deviceProduct(service)
        if trigger && !shouldIgnore(service) {
            requestKanataRestart(reason: "\(event) \(product)")
        }
        IOObjectRelease(service)
    }
}

// Callbacks
let matchCallback: IOServiceMatchingCallback = { refcon, iterator in
    drainIterator(iterator, event: "attached", trigger: true)
}

let removalCallback: IOServiceMatchingCallback = { refcon, iterator in
    drainIterator(iterator, event: "detached", trigger: true)
}

// Set up IOKit notification port
guard let notifyPort = IONotificationPortCreate(kIOMainPortDefault) else {
    log("Error: failed to create IONotificationPort")
    exit(1)
}
notifyPortRef = notifyPort

let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue()
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

// Watch for USB device attach
var matchIterator: io_iterator_t = 0
let matchDict = IOServiceMatching(kIOUSBDeviceClassName)
let matchResult = IOServiceAddMatchingNotification(
    notifyPort,
    kIOFirstMatchNotification,
    matchDict,
    matchCallback,
    nil,
    &matchIterator
)
guard matchResult == kIOReturnSuccess else {
    log("Error: failed to register match notification (0x\(String(matchResult, radix: 16)))")
    exit(1)
}
// Drain existing devices without triggering restart
drainIterator(matchIterator, event: "existing", trigger: false)

// Watch for USB device detach
var removeIterator: io_iterator_t = 0
let removeDict = IOServiceMatching(kIOUSBDeviceClassName)
let removeResult = IOServiceAddMatchingNotification(
    notifyPort,
    kIOTerminatedNotification,
    removeDict,
    removalCallback,
    nil,
    &removeIterator
)
guard removeResult == kIOReturnSuccess else {
    log("Error: failed to register removal notification (0x\(String(removeResult, radix: 16)))")
    exit(1)
}
// Drain existing terminated entries
drainIterator(removeIterator, event: "existing-removed", trigger: false)

log("Watching for USB device changes...")

// Run forever
CFRunLoopRun()
