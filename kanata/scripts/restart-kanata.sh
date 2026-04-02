#!/usr/bin/env bash
# restart-kanata.sh — Restart kanata when triggered by the keyboard watcher.
#
# Runs as a LaunchDaemon (root). Triggered via WatchPaths on /tmp/kanata-restart-trigger,
# which the kanata-watcher LaunchAgent touches when it detects a keyboard change.
set -euo pipefail

LOG_PREFIX="$(date '+%Y-%m-%d %H:%M:%S')"

echo "$LOG_PREFIX Restarting kanata..."
if launchctl kickstart -k system/com.jtroo.kanata; then
  sleep 3
  if launchctl print system/com.jtroo.kanata 2>&1 | grep -q "state = running"; then
    echo "$LOG_PREFIX Kanata restarted successfully"
  else
    echo "$LOG_PREFIX Kanata restart issued (could not verify state)"
  fi
else
  echo "$LOG_PREFIX Failed to restart kanata" >&2
  exit 1
fi
