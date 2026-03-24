#!/usr/bin/env bash
# Watches for HID device changes and restarts kanata when detected.
# Uses ioreg IOHIDDevice class which sees ALL HID devices (USB, BT, dock).
# Excludes Apple built-in, Karabiner virtual, and non-keyboard peripherals.
# Runs as a LaunchDaemon (root) — no sudo needed for launchctl.

INTERVAL=5
COOLDOWN=10

LAST=""

get_devices() {
  ioreg -r -c IOHIDDevice 2>/dev/null \
    | grep -E '"Product"|"Manufacturer"' \
    | grep -vi "karabiner\|virtual\|Backlight\|SMC\|pqrs" \
    | sort
}

while true; do
  CURRENT=$(get_devices)
  if [ -n "$LAST" ] && [ "$CURRENT" != "$LAST" ]; then
    logger -t kanata-watcher "HID device change detected, restarting kanata"
    launchctl kickstart -k system/com.jtroo.kanata
    LAST=""  # reset so next poll re-establishes baseline
    sleep "$COOLDOWN"
  else
    LAST="$CURRENT"
    sleep "$INTERVAL"
  fi
done
