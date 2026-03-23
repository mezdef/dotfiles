// Karabiner-Elements configuration generator
//
// Builds karabiner.json from TypeScript and writes it to the stow-managed
// karabiner/ package (not directly to ~/.config). This means:
//   - Fresh machine: just `stow karabiner` — no Node.js needed
//   - Editing config: modify TypeScript, run `npm run build` or ./scripts/deploy.sh
//
// writeToProfile only updates complex_modifications and parameters.
// It preserves other profile fields (devices, virtual_hid_keyboard, etc.)
// and the global settings already in karabiner.json.
//
// Usage:
//   npm run build     — generate karabiner.json
//   npm run dry-run   — print to stdout without writing

import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'
import { writeToProfile } from 'karabiner.ts'

// import { homeRowModsRule } from './rules/home-row-mods'
import { homeRowModsRules } from './rules/home-row-mods-greg'
import { spotlightRule } from './rules/spotlight'
import { hyperKeyRule } from './rules/hyper-key'

const dryRun = process.argv.includes('--dry-run')

const __dirname = dirname(fileURLToPath(import.meta.url))
const karabinerJsonPath = resolve(
  __dirname,
  '../../karabiner/.config/karabiner/karabiner.json',
)

const rules = [
  ...homeRowModsRules,
  spotlightRule,
  hyperKeyRule,
]

// See home-row-mods.ts header comment for detailed timing tradeoff explanation
const parameters = {
  'basic.simultaneous_threshold_milliseconds': 100,
  'basic.to_if_alone_timeout_milliseconds': 300,
  'basic.to_if_held_down_threshold_milliseconds': 150,
} as const

writeToProfile(
  dryRun
    ? '--dry-run'
    : { name: 'Default profile', karabinerJsonPath },
  rules,
  parameters,
)
