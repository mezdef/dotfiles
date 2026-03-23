// Cmd+Space → Hyper+Space
//
// macOS default spotlight shortcut is cmd+space. Since caps_lock is remapped
// to hyper (ctrl+opt+cmd), we remap cmd+space to hyper+space so that both
// cmd+space and caps_lock+space trigger the same action (e.g. Raycast).
//
// lazy: false  — send the keypress immediately, don't wait for a subsequent key
// repeat: false — don't repeat on hold, single trigger only

import { map, rule, toKey } from 'karabiner.ts'

export const spotlightRule = rule(
  '⌘ + Spacebar → Hyper(⌃⌥⌘) + Spacebar | Mimic OSX default spotlight',
).manipulators([
  map('spacebar', 'left_command').to(
    toKey('spacebar', ['left_control', 'left_option', 'left_command'], {
      lazy: false,
      repeat: false,
    }),
  ),
])
