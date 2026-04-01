# Kanata (keyboard remapping)

Replaces Karabiner-Elements for home row mods, hyper key, and spotlight remap.
Requires the Karabiner-DriverKit-VirtualHIDDevice driver (keep Karabiner installed).

## Setup

```bash
brew install kanata
stow kanata                              # symlinks .config/kanata/ to ~/.config/kanata/
sudo ./kanata/scripts/install-daemon.sh  # installs LaunchDaemon (runs as root on boot)
```

Grant in System Settings → Privacy & Security:
- Input Monitoring → `/opt/homebrew/bin/kanata`
- Accessibility → `/opt/homebrew/bin/kanata`

## Files

```
kanata/
├── .config/kanata/
│   ├── kanata.kbd          ← entry point (defcfg, defsrc, includes)
│   ├── hyper.kbd           ← caps lock → hyper (ctrl+opt+cmd), tap → esc
│   └── home-row-mods.kbd  ← per-finger timing, typing layer, spotlight remap
├── com.jtroo.kanata.plist  ← LaunchDaemon definition (not stowed)
├── scripts/
│   └── install-daemon.sh   ← installs plist to /Library/LaunchDaemons/
└── .stow-local-ignore      ← excludes plist/scripts/README from stow
```

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
