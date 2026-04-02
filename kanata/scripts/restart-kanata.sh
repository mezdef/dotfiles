#!/usr/bin/env bash
# restart-kanata.sh — Restart kanata when triggered by the keyboard watcher.
#
# Runs as a LaunchDaemon (root). Triggered via WatchPaths on /tmp/kanata-restart-trigger,
# which the kanata-watcher LaunchAgent touches when it detects a keyboard change.
#
# USB devices through docks enumerate over several seconds — the keyboard may
# appear 2-5s after the first hub. We restart twice: once immediately (for devices
# already present) and again after 8s (for late arrivals like keyboards behind
# multiple hub layers).
set -euo pipefail

do_restart() {
  local label="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Restarting kanata ($label)..."
  if launchctl kickstart -k system/com.jtroo.kanata; then
    sleep 3
    if launchctl print system/com.jtroo.kanata 2>&1 | grep -q "state = running"; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') Kanata restarted successfully ($label)"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') Kanata restart issued ($label, could not verify state)"
    fi
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Failed to restart kanata ($label)" >&2
    return 1
  fi
}

# First restart — grab devices already on the bus
do_restart "immediate"

# Second restart — catch keyboards that enumerate late through dock/hub chains
sleep 8
do_restart "delayed"
