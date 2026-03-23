// Home Row Mods
//
// Turns the home row keys into modifier keys when held, while preserving
// their normal letter output when tapped.
//
// Layout:
//   Left hand:  a=ctrl  s=opt  d=cmd  f=shift
//   Right hand: ;=ctrl  l=opt  k=cmd  j=shift
//
// Three activation mechanisms:
//
// 1. SINGLE-KEY HOLD
//    Hold any home row key for to_if_held_down_threshold (150ms) and it
//    activates as its modifier. Tap quickly and it types the letter.
//
// 2. SIMULTANEOUS COMBOS
//    Press 2+ modifier keys on the same hand together (within
//    simultaneous_threshold of 100ms) to stack multiple modifiers at once.
//    Modifiers activate immediately — no additional held_down delay.
//    Examples:
//      a+f together → ctrl+shift
//      a+s+d together → ctrl+opt+cmd
//      a+s+d+f together → ctrl+opt+cmd+shift
//
// 3. SHIFT + HYPER (caps lock combos)
//    Press f or j simultaneously with caps_lock to get shift+hyper
//    (shift+ctrl+opt+cmd). Needed because pressing them sequentially
//    doesn't work — caps lock cancels the shift key's hold detection.
//    Also supports the reverse order: hold hyper first, then press f/j
//    to add shift (see hyperShiftCombos).
//
// The to_delayed_action mechanism:
//   When you press a modifier key and then quickly press another key
//   (before the held_down threshold), to_if_canceled fires and outputs
//   the original letter. This prevents lost keystrokes during fast typing.
//
// Timing tradeoffs:
//   - to_if_held_down_threshold (150ms): Main knob for typing accuracy vs
//     modifier speed. Higher = fewer false modifiers but slower activation.
//   - simultaneous_threshold (100ms): How quickly combo keys must be pressed.
//     Higher = easier combos but risk false triggers on words like "sad", "fast".
//   - to_if_alone_timeout (300ms): Max hold time that still counts as a tap.
//   - Sequential stacking: Each single-key mod needs its own held_down delay,
//     so stacking 2 mods sequentially takes 2x threshold. Use simultaneous
//     combos for faster stacking.

import {
  map,
  mapSimultaneous,
  rule,
  toKey,
  toNone,
  type FromKeyParam,
  type Modifier,
} from 'karabiner.ts'

const leftKeys = [
  { key: 'a' as const, mod: 'left_control' as Modifier },
  { key: 's' as const, mod: 'left_option' as Modifier },
  { key: 'd' as const, mod: 'left_command' as Modifier },
  { key: 'f' as const, mod: 'left_shift' as Modifier },
]

const rightKeys = [
  { key: 'semicolon' as const, mod: 'right_control' as Modifier },
  { key: 'l' as const, mod: 'right_option' as Modifier },
  { key: 'k' as const, mod: 'right_command' as Modifier },
  { key: 'j' as const, mod: 'right_shift' as Modifier },
]

// Generate all combinations of size k from an array
function combinations<T>(arr: T[], k: number): T[][] {
  if (k === 1) return arr.map((x) => [x])
  const result: T[][] = []
  for (let i = 0; i <= arr.length - k; i++) {
    for (const rest of combinations(arr.slice(i + 1), k - 1)) {
      result.push([arr[i], ...rest])
    }
  }
  return result
}

// Generates all 2-key, 3-key, and 4-key simultaneous combos for one hand.
// Longer combos are listed first so Karabiner matches them with higher priority.
// Each combo's to_if_alone outputs all original letters so fast typing isn't lost.
function simultaneousCombos(keys: typeof leftKeys) {
  const manipulators = []

  for (let size = keys.length; size >= 2; size--) {
    for (const combo of combinations(keys, size)) {
      const simKeys = combo.map((k) => k.key) as FromKeyParam[]
      const aloneKeys = combo.map((k) => toKey(k.key))
      const [first, ...rest] = combo
      const modifiers = rest.map((k) => k.mod)

      manipulators.push(
        mapSimultaneous(simKeys)
          .toIfAlone(aloneKeys)
          .to(toKey(first.mod, modifiers)),
      )
    }
  }

  return manipulators
}

// Individual key hold-for-mod. Each key:
//   - Tapped alone → outputs the letter (halt: true stops further processing)
//   - Held past threshold → activates as modifier
//   - Pressed then quickly followed by another key → to_if_canceled outputs
//     the letter, preventing lost keystrokes during fast typing
function holdForMod(keys: typeof leftKeys) {
  return keys.map(({ key, mod }) =>
    map(key)
      .toIfAlone(toKey(key, undefined, { halt: true }))
      .toIfHeldDown(toKey(mod, undefined, { halt: true }))
      .toDelayedAction(
        [toNone()],   // to_if_invoked: key held long enough, do nothing extra
        [toKey(key)], // to_if_canceled: key released early, output the letter
      ),
  )
}

// Hyper (caps_lock held) + f/j → adds shift to hyper.
// Handles the case where caps_lock is held first, then f/j is pressed.
// Caps lock is already remapped to ctrl+opt+cmd by hyper-key.ts, so we
// match f/j with those mandatory modifiers and add shift.
function hyperShiftCombos() {
  const hyperMods: Modifier[] = ['left_control', 'left_option', 'left_command']
  return [
    map('f', hyperMods).to('left_shift', hyperMods),
    map('j', hyperMods).to('right_shift', hyperMods),
  ]
}

// f/j + caps_lock pressed simultaneously → shift + hyper.
// Handles the case where f/j and caps_lock are pressed at the same time
// (within simultaneous_threshold). Complements hyperShiftCombos above
// which handles the sequential "hyper first, then shift" ordering.
function capsShiftCombos() {
  return [
    mapSimultaneous(['f', 'caps_lock'])
      .toIfAlone([toKey('f'), toKey('escape')])
      .to('left_shift', ['left_control', 'left_option', 'left_command']),
    mapSimultaneous(['j', 'caps_lock'])
      .toIfAlone([toKey('j'), toKey('escape')])
      .to('right_shift', ['left_control', 'left_option', 'left_command']),
  ]
}

// Manipulator order matters — Karabiner uses the first match.
// Priority: caps combos > hyper+shift > simultaneous combos > hold-for-mod
export const homeRowModsRule = rule(
  'Home row mods - ctrl, opt, cmd, shift',
).manipulators([
  ...capsShiftCombos(),
  ...hyperShiftCombos(),
  ...simultaneousCombos(leftKeys),
  ...simultaneousCombos(rightKeys),
  ...holdForMod(leftKeys),
  ...holdForMod(rightKeys),
])
