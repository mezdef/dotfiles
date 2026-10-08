#!/bin/bash
# Shares every top-level dir in ~/Filesync with the mini through Syncthing; `_`-prefixed dirs stay
# local. Idempotent. Client side of media-server's tools/syncthing/configure.sh; never stow on the mini.
set -euo pipefail
API=http://127.0.0.1:8384
KEY=$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$HOME/Library/Application Support/Syncthing/config.xml")
ENV=$HOME/.config/filesync/env # MINI (device ID) and MINI_HOST; template in env.example
[ -r "$ENV" ] || { echo "filesync-configure: $ENV missing, copy env.example" >&2; exit 1; }
. "$ENV"
FILESYNC=$HOME/Filesync
TAILSCALE=$(command -v tailscale || echo /Applications/Tailscale.app/Contents/MacOS/Tailscale)
TAILNET_IP=$("$TAILSCALE" ip -4)

st() { # method path [json]
  curl -fsS -m 60 -X "$1" -H "X-API-Key: $KEY" -H 'Content-Type: application/json' \
    ${3:+--data "$3"} "$API$2"
}

# Tailnet-only listener, no discovery, relays, NAT or reporting, as on the mini.
st PATCH /rest/config/options "$(jq -nc --arg ip "$TAILNET_IP" '{
  listenAddresses: ["tcp://\($ip):22000"],
  globalAnnounceEnabled: false, localAnnounceEnabled: false,
  relaysEnabled: false, natEnabled: false,
  urAccepted: -1, crashReportingEnabled: false
}')"
# Folders the mini offers stay opt-in here.
st PUT "/rest/config/devices/$MINI" "$(jq -nc --arg id "$MINI" --arg name "$MINI_HOST" \
  '{deviceID: $id, name: $name, addresses: ["tcp://\($name):22000"], autoAcceptFolders: false}')" >/dev/null

folders=$(st GET /rest/config/folders)
for dir in "$FILESYNC"/*/; do
  [ -d "$dir" ] || continue
  path=${dir%/} name=$(basename "$dir")
  case $name in _*) continue ;; esac
  # A folder already at this path keeps its ID, e.g. one accepted from the mini.
  id=$(jq -r --arg path "$path" --arg home "$HOME" \
    'map(select((.path | sub("^~"; $home) | rtrimstr("/")) == $path)) | .[0].id // empty' <<<"$folders")
  [ -n "$id" ] || id=$(printf '%s' "$name" | tr '[:upper:] ' '[:lower:]-')
  current=$(jq -c --arg id "$id" 'map(select(.id == $id)) | .[0] // null' <<<"$folders")
  st PUT "/rest/config/folders/$id" "$(jq -nc --argjson cur "$current" --arg id "$id" --arg path "$path" \
    --arg label "$name" --arg mini "$MINI" '($cur // {label: $label}) + {
      id: $id, path: $path, type: "sendreceive", fsWatcherEnabled: true,
      devices: ((($cur.devices // []) + [{deviceID: $mini}]) | unique_by(.deviceID))
    }')" >/dev/null
  # The mini writes .stglobalignore into the folder and it syncs back here.
  [ -e "$path/.stignore" ] || printf '#include .stglobalignore\n' > "$path/.stignore"
done

st GET /rest/config/folders | jq -r '.[] | "\(.id) \(.path) devices=\(.devices | length)"'
