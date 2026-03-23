// Caps Lock → Hyper Key (ctrl+opt+cmd)
//
// Remaps caps_lock to a "hyper" modifier (ctrl+opt+cmd held simultaneously).
// This creates a new modifier layer for keybindings that won't conflict with
// any application shortcuts.
//
// Behavior:
//   - Held: activates ctrl+opt+cmd (hyper) — combine with any key for shortcuts
//   - Tapped alone: outputs Escape (useful for vim)
//   - fn + caps_lock: toggles actual caps lock (macOS built-in behavior)
//
// The { optional: 'any' } modifier allows caps_lock to combine with other
// modifiers (like shift from home row mods) without blocking the mapping.

import { map, rule } from 'karabiner.ts'

export const hyperKeyRule = rule(
  'Caps Lock → Hyper Key (⌃⌥⌘) | Escape if alone | Use fn + caps lock to enable caps lock',
).manipulators([
  map('caps_lock', { optional: 'any' })
    .to('left_command', ['left_control', 'left_option'])
    .toIfAlone('escape'),
])
