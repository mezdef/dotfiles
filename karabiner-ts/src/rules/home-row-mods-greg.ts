// Home Row Mods (hybrid: our simultaneous combos + greg-mods single-key hold)
//
// Combines two systems:
//   1. Our simultaneousCombos — 2/3/4-key modifier stacking (from home-row-mods.ts)
//   2. greg-mods hrm() — single-key hold-for-mod with key replay
//
// greg-mods chordalHold is disabled — its chord detection causes false triggers
// on fast same-hand sequences (e.g. "ds" in "lads"). Our simultaneousCombos
// handle multi-key modifier stacking instead.
//
// Layout:
//   Left hand:  a=ctrl  s=opt  d=cmd  f=shift
//   Right hand: ;=ctrl  l=opt  k=cmd  j=shift
//
// Split into two Karabiner rules so our combos fully consume key events
// before greg-mods' layer activators can see them.
//
// Rule 1 priority (first match wins):
//   1. capsShiftCombos — f/j + caps_lock simultaneously
//   2. hyperShiftCombos — hyper held + f/j
//   3. simultaneousCombos — all 2/3/4-key combos per hand
//   4. modifierPassthrough — home row keys with physical modifiers held
// Rule 2: greg-mods single-key hold-for-mod (with key replay)
//
// Timing:
//   - tappingTerm: 150ms — tap/hold decision threshold (greg-mods)
//   - simultaneousThreshold: 100ms — chord detection window (greg-mods)
//   - basic.simultaneous_threshold: 100ms — for mapSimultaneous combos (set in index.ts)
//
// See home-row-mods.ts for the original fully hand-rolled implementation.
// To roll back: change the import in index.ts back to './home-row-mods'.

import {
  map,
  mapSimultaneous,
  rule,
  toKey,
  type FromKeyParam,
  type Modifier,
} from 'karabiner.ts'
import { hrm } from 'karabiner.ts-greg-mods'

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

// Hyper (caps_lock held) + f/j → adds shift to hyper.
function hyperShiftCombos() {
  const hyperMods: Modifier[] = ['left_control', 'left_option', 'left_command']
  return [
    map('f', hyperMods).to('left_shift', hyperMods),
    map('j', hyperMods).to('right_shift', hyperMods),
  ]
}

// f/j + caps_lock pressed simultaneously → shift + hyper.
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

// Pass-through for home row keys when any physical modifier is already held.
// greg-mods intercepts these keys with `optional: any`, which swallows
// keypresses like ctrl+shift+l. These rules match first (mandatory: any
// requires at least one modifier held) and let the keypress through unchanged.
function modifierPassthrough(keys: typeof leftKeys) {
  return keys.map(({ key }) => map(key, 'any').to(key))
}

const gregModsManipulators = hrm(
  new Map([
    ['a', 'l⌃'],
    ['s', 'l⌥'],
    ['d', 'l⌘'],
    ['f', 'l⇧'],
    ['j', 'r⇧'],
    ['k', 'r⌘'],
    ['l', 'r⌥'],
    [';', 'r⌃'],
  ]),
)
  .chordalHold(false)
  .triples(false)
  .simultaneousThreshold(100)
  .tappingTerm(150)
  .build()

// Split into two rules so Karabiner fully resolves our simultaneous combos
// before greg-mods' layer activators can see the key events.
const combosRule = rule(
  'Home row mods - combos',
).manipulators([
  ...capsShiftCombos(),
  ...hyperShiftCombos(),
  ...simultaneousCombos(leftKeys),
  ...simultaneousCombos(rightKeys),
  ...modifierPassthrough(leftKeys),
  ...modifierPassthrough(rightKeys),
])

const holdRule = rule(
  'Home row mods - hold (greg-mods)',
).manipulators([
  ...gregModsManipulators,
])

export const homeRowModsRules = [combosRule, holdRule]
