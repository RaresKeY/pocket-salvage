# CC0 event audio

Imported 2026-09-28 for the god, damage, relic and hidden-ending cues in `assets/audio/sfx/events/`. Dale chose free CC0 sources over the Omni workflow for these; any cue can be replaced later by swapping its files, since `scripts/audio/game_audio.gd` `CUES` refers to them by name. Selected by the assistant (Darwin) from an audition shortlist Dale approved.

## Sources

All four are CC0 1.0 (public domain dedication). No attribution is required; they are credited on the itch page anyway.

| Download | Author | Page | SHA-256 |
|---|---|---|---|
| `kenney_impact-sounds.zip` (800,850 bytes) | Kenney | <https://kenney.nl/assets/impact-sounds> | `029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8` |
| `100-CC0-SFX_0.zip` (2,921,904 bytes) | rubberduck | <https://opengameart.org/content/100-cc0-sfx> | `a5c135878c132f1c59cca54e60061c296cd0ac27ad031ca2c41b8cd5cab3c706` |
| `sfx_100_v2.zip` (2,367,871 bytes) | rubberduck | <https://opengameart.org/content/100-cc0-sfx-2> | `0fc61b4494e2e893c0c015ced4877b3f689c7d84a48cb61daecd7ddb52db797b` |
| `wind woosh loop.ogg` (251,584 bytes) | SketchMan3 | <https://opengameart.org/content/wind-whoosh-loop> | `0cfdbd3f21ed449689a9024264edf267d0037a6495813a7010827672ec191dac` |

The downloads stay outside the repository. Rebuild with `python3 tools/audio/build_event_cues.py <folder with the unzipped packs>` (needs ffmpeg).

## Cues

| Cue | File | Source | Edit |
|---|---|---|---|
| `lightning` | `thunder_short.ogg` | `sfx100v2_thunder_01.ogg` | first 2.5 s, 0.7 s fade out |
| `gust` | `wind_gust.ogg` | `wind woosh loop.ogg` | 1.0 to 2.6 s, fades in 0.3 s and out 0.6 s, +10 dB |
| `ceramic_crack` | `plate_light_0..2.ogg` | Kenney `impactPlate_light_000..002.ogg` | copied |
| `cup_break` | `dishes_1..4.ogg` | `dishes_01..04.ogg` | copied |
| `relic_stir` | `stones_low.ogg` | `sfx100v2_stones_02.ogg` | slowed to 0.7x, low pass 1.5 kHz |
| `relic_awaken` | `gong.ogg` | `gong_01.ogg` | copied |
| `glyph` | `bell.ogg` | `bell_01.ogg` | copied |
| `ending_rumble` | `rumble.ogg` | `sfx100v2_thunder_01.ogg` | slowed to 0.6x, low pass 400 Hz, +4 dB |
| `ending_title` | `bell.ogg` | `bell_03.ogg` | copied |

`ceramic_crack` and `cup_break` are ready for R's Medusa cracking work and not yet called by the game.
