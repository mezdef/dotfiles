# Kanata (keyboard remapping)

Replaces Karabiner-Elements for home row mods, hyper key, and spotlight remap.
Requires the Karabiner-DriverKit-VirtualHIDDevice driver (keep Karabiner installed).

## Setup

```bash
brew install kanata
stow kanata  # symlinks .config/kanata/ to ~/.config/kanata/
```

The LaunchDaemon that runs kanata at boot and the watcher that restarts it on keyboard connect are
installed from a separate tools repo, not this one.

Grant in System Settings → Privacy & Security:
- Input Monitoring → `/opt/homebrew/bin/kanata`
- Accessibility → `/opt/homebrew/bin/kanata`

## Upgrading

`setup.sh` pins kanata, so `brew bundle` never upgrades it: an upgrade drops the Input Monitoring
grant and kanata then doubles every keypress. Upgrade on purpose:

```bash
brew unpin kanata && brew upgrade kanata && brew pin kanata
```

Then re-grant Input Monitoring to `/opt/homebrew/bin/kanata` and run
`sudo launchctl kickstart -k system/com.jtroo.kanata`.

## Files

```
kanata/
├── .config/kanata/
│   ├── kanata.kbd                     ← entry point (defcfg, defsrc, includes)
│   ├── hyper.kbd                      ← caps lock → hyper (ctrl+opt+cmd), tap → esc
│   ├── home-row-mods.kbd              ← per-finger timing, typing layer, spotlight remap
│   ├── scroll.kbd                     ← page up/down, top/bottom bindings
│   └── layers.kbd                     ← deflayermap per layer (one file per layer name)
└── .stow-local-ignore                 ← excludes README from stow
```

`kanata.kbd` includes the other four `.kbd` files, so a new layer must be added to
`layers.kbd` (or included explicitly) to take effect.

## Editing

Edit `.kbd` files in `.config/kanata/`. Restart kanata to apply changes:

```bash
sudo launchctl kickstart -k system/com.jtroo.kanata
```

## Managing the daemon

```bash
sudo launchctl kickstart system/com.jtroo.kanata   # restart
sudo launchctl kill SIGTERM system/com.jtroo.kanata # stop
sudo launchctl bootout system /Library/LaunchDaemons/com.jtroo.kanata.plist # uninstall
```

## Logs

```bash
tail -f /Library/Logs/Kanata/kanata.err.log
```

## Rollback to Karabiner

1. Stop kanata: `sudo launchctl bootout system /Library/LaunchDaemons/com.jtroo.kanata.plist`
2. Launch Karabiner-Elements — existing config auto-loads
