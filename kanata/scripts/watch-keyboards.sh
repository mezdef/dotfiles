#!/usr/bin/env bash
# Event-driven HID device watcher for kanata.
# Uses IOKit HID Manager notifications (via Swift) to detect keyboard
# attach/detach instantly and restart kanata so it grabs the new device.
#
# Runs as a LaunchDaemon (root) via com.jtroo.kanata-watcher.plist.
# Root is required for both IOHIDManagerOpen and launchctl kickstart.
#
# See watch-keyboards.swift for design decisions (why event-driven,
# why we match all HID devices, tested keyboards, exclusion strategy).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec swift "$SCRIPT_DIR/watch-keyboards.swift"
