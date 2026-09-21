# World 0 gameplay SFX

Curated runtime selection from **SciFi Sound Design Pack — Volume 1** by Clint
Wagoner. The source library stays under `assets/sounds/`, excluded from Godot
with `.gdignore`; only these renamed files are imported and shipped.

| Runtime file | Original file |
|---|---|
| `jump.wav` | `SpaceShips/SciFi-V1_SpaceShip-FlyAway2_24b_44k.wav` |
| `player_fire.wav` | `Weapons/SciFi-V1_Blaster1.wav` |
| `impact_allowed.wav` | `Weapons/SciFi-V1_Weapons_05_24b-48k.wav` |
| `impact_blocked.wav` | `Bonus/Glitch/SciFi-V1_Glitch_Effect_03.wav` |
| `threat.wav` | `TensionFX/SciFi-V1_Tension_15_24b-48k.wav` |
| `aggression.wav` | `Weapons/SciFi-V1_Weapons_03_24b-48k.wav` |
| `surrender.wav` | `Bonus/Glitch/SciFi-V1_Glitch_Effect_13.wav` |
| `pickup.wav` | `Bonus/Granular/SciFi-V1_Up.wav` (runtime limited to a short ascending confirmation) |
| `gate_open.wav` | `SpaceShips/SciFi-V1_SpaceShip-FlyAway1_24b_44k.wav` |
| `rule_interaction.wav` | `Bonus/Glitch/SciFi-V1_Glitch_Effect_02.wav` |
| `contract_state.wav` | `Weapons/SciFi-V1_Weapons_02_24b-48k.wav` (retained in the curated library; runtime contract feedback currently reuses the shorter `rule_interaction` cue) |
| `encounter_resolved.wav` | `Bonus/Glitch/SciFi-V1_Glitch_Effect_14.wav` |
| `checkpoint.wav` | `Bonus/Granular/SciFi-V1_Up.wav` (runtime limited to a longer ascending confirmation) |
| `boss_phase.wav` | `TensionFX/SciFi-V1_Tension_14_24b-48k.wav` |
| `level_complete.wav` | `Bonus/Granular/SciFi-V1_Up.wav` |

The mapping is intentionally controlled by
`data/audio/world0_gameplay_audio.tres`, so individual sounds can be replaced
without changing gameplay scripts.

## Project-original retro cues

The short state, pickup, machine and checkpoint cues under `generated/` are
deterministically synthesized by `tools/audio/generate_retro_cues.ps1`. They
are original project assets and replace longer SciFi samples where a concise
16-bit-style confirmation reads better during gameplay. Warped was audited
first; its audio bundle contains complete music tracks rather than isolated UI
or status effects.
