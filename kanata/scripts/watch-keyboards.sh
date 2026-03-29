#!/usr/bin/env bash
# Watches for HID device changes and restarts kanata when detected.
# Uses ioreg IOHIDDevice class which sees ALL HID devices (USB, BT, dock).
# Excludes Apple built-in, Karabiner virtual, and non-keyboard peripherals.
# Runs as a LaunchDaemon (root) — no sudo needed for launchctl.

INTERVAL=5
COOLDOWN=10
MAX_RETRIES=3

LAST=""

get_devices() {
  ioreg -r -c IOHIDDevice 2>/dev/null \
    | grep -i '"Product"' \
    | grep -vi "Backlight\|SMC\|Headset\|BTM" \
    | sort
}

restart_kanata() {
  local attempt
  for attempt in $(seq 1 "$MAX_RETRIES"); do
    logger -t kanata-watcher "Restarting kanata (attempt $attempt/$MAX_RETRIES)"
    launchctl kickstart -k system/com.jtroo.kanata
    sleep 3
    if launchctl print system/com.jtroo.kanata 2>/dev/null | grep -q "state = running"; then
      logger -t kanata-watcher "Kanata restarted successfully"
      return 0
    fi
    sleep 2
  done
  logger -t kanata-watcher "Kanata failed to restart after $MAX_RETRIES attempts"
  return 1
}

while true; do
  CURRENT=$(get_devices)
  if [ -n "$LAST" ] && [ "$CURRENT" != "$LAST" ]; then
    logger -t kanata-watcher "HID device change detected"
    restart_kanata
    LAST=""  # reset so next poll re-establishes baseline
    sleep "$COOLDOWN"
  else
    LAST="$CURRENT"
    sleep "$INTERVAL"
  fi
done
