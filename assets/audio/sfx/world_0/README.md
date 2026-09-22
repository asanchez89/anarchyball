# World 0 gameplay SFX

`tactical_dash.wav`: short whoosh for tactical relays, trimmed from Clint Wagoner's
`SpaceShips/SciFi-V1_SpaceShips_18-FlyBy14_24b-48k.wav`. Deterministic 0.32 s mono
excerpt with entrance/exit fades; reproduce with `tools/audio/prepare_tactical_dash.ps1`.
Plays once per exchange at the withdrawing actor, never per movement frame or restore.

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

## Alert and gate feedback

Runtime uses distinct short project-original cues for dispute (two uncertain
notes), threat (double beep), committed aggression (descending alarm),
surrender (ascending release), alert clear (descending calm), direct
neutralization (short success) and gate opening (five-note ascending unlock).
The new gate cue replaces the long spaceship sample; the source file remains
in the library. Generation is reproducible with the same PowerShell script.

State sounds fire on transitions, not patrol/animation ticks. Surrender followed
by neutralization does not play a second success cue. Checkpoint restoration is
silent. Simultaneous copies of an alert within 120 ms share one cue per viewport
and audio profile, preventing collective encounters from stacking identical
alarms; inaudible distant actors do not consume that window.

AccessGate.open_for_resolution emits opened exactly once per closed-to-open
transition. Challenge, contract and key/tag openings use that event. restore_open
remains silent for checkpoint reconstruction. Regenerating existing cues is
deterministic; the bought source sound packs are not modified.

Validation: headless import and 215 tests pass. Coverage includes transition
mapping, duplicate suppression, short asset duration, checkpoint silence and
the first Police encounter opening its gate. Perceptual volume/timbre balance
still needs an in-game listening pass; no controls were changed.

### Spatial alert correction

The emitter is now Node2D in both actor scenes. A plain Node between actor and
AudioStreamPlayer2D broke transform inheritance: the voice remained at (0, 0),
so alerts at x=6480 were rejected as too distant. The new regression checks
actual inherited coordinates, not only calls to play_cue.

Threat now uses detection_alert_retro.wav: original 0.323-second metallic
pitch-swept stinger, synthesized without external samples. It evokes a sudden
stealth-game detection, not a reproduction of Metal Gear audio. Threat gets
a configurable +5 dB offset and aggression +2 dB, leaving the mix unchanged.
Other conflict states retain their distinct cues and collective coalescing.

tools/audio/check_world_alerts.gd runs the graphical engine with the Dummy audio
driver and captures the actual mix via AudioEffectCapture. It triggers a real
Threatening transition at x=6480 and x=19200, checking source alignment,
cue acceptance and nonzero output. This complements headless event tests.
