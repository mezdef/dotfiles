# Karabiner Home Row Mods

## Layout

```
Left hand modifiers:        Right hand modifiers:
a = ctrl                    ; = ctrl
s = opt                     l = opt
d = cmd                     k = cmd
f = shift                   j = shift
```

## How it works

### Single-key hold
Hold any modifier key for `to_if_held_down_threshold` (150ms) and it activates as its modifier. Tap it quickly and it types the letter normally.

### Modifier stacking (simultaneous combos)
Press two or more modifier keys on the **same hand** together (within `simultaneous_threshold` of 100ms) to activate multiple modifiers at once. Modifiers activate immediately when the combo is detected (no additional held_down delay).

Examples:
- `a+f` pressed together = ctrl+shift
- `a+s+d` pressed together = ctrl+opt+cmd
- `a+s+d+f` pressed together = ctrl+opt+cmd+shift

Example workflow for ctrl+shift+h:
1. Press `a` and `f` together (within 100ms of each other)
2. Keep holding them (~100ms for simultaneous detection to confirm)
3. Press `h`

### Shift + Hyper (caps lock)
Press `f` or `j` simultaneously with `caps_lock` to get shift+hyper (shift+ctrl+opt+cmd). This is needed because pressing them sequentially doesn't work — caps lock cancels the shift key's hold detection.

- `f+caps_lock` held + any key = left_shift+ctrl+opt+cmd+key
- `j+caps_lock` held + any key = right_shift+ctrl+opt+cmd+key

### The `to_delayed_action` mechanism
When you press a modifier key and then quickly press another non-modifier key (before the held_down threshold), `to_if_canceled` fires and outputs the original letter. This prevents lost keystrokes during fast typing.

## Timing parameters

| Parameter | Value | Purpose |
|---|---|---|
| `simultaneous_threshold` | 100ms | Window for keys pressed together to count as a simultaneous combo. Lower = less typing interference but harder to trigger combos. |
| `to_if_alone_timeout` | 300ms | Max time a key can be held and still register as a tap (letter output). |
| `to_if_held_down_threshold` | 150ms | Min time a key must be held before it activates as a modifier. Higher = fewer false positives during typing but slower modifier activation. |

## Tuning tradeoffs

- **Typing accuracy vs modifier speed**: `to_if_held_down_threshold` is the main knob. Higher values prevent false modifiers during typing but make single-key modifier activation slower.
- **Combo speed vs typing accuracy**: `simultaneous_threshold` controls how quickly you must press combo keys. Higher values make combos easier but risk false combos when typing words like "sad", "fast", "silk".
- **Sequential stacking**: Each single-key modifier needs its own `to_if_held_down_threshold` to activate. Stacking two modifiers sequentially takes 2x the threshold. Use simultaneous combos for faster stacking.

## Other rules

- **Caps Lock**: Hyper key (ctrl+opt+cmd) when held, Escape when tapped. Accepts any modifier as optional so it combines with home row mods.
- **Cmd+Space**: Remapped to ctrl+opt+cmd+space (Hyper+Space) for spotlight compatibility
- **Device-specific**: Left cmd/opt swapped on external keyboard (vendor 21057, product 2058)

## Deploying changes

Karabiner doesn't follow symlinks for live-reload. After editing `karabiner.json`, copy to the live config:

```sh
rm ~/.config/karabiner/karabiner.json
cp karabiner.json ~/.config/karabiner/karabiner.json
```
