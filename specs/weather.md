# Weather

Reviewed: 2026-09-25. Implementation: tapered wind change based on `5036ebd`.

Each salvage round uses its selected level’s weather that physically changes how the crane works and multiplies a positive final score. Intent and the split between Dale's direction and AI choices are in [design/weather.md](../design/weather.md).

## Ownership

| Source | Role |
|---|---|
| `scripts/weather/weather_profile.gd` | `WeatherProfile` resource: the data fields only |
| `data/weather/*.tres` | The five profiles: clear, fog, wind, rain, storm |
| `scripts/weather/weather.gd` | Picks a profile, runs the gust and lightning clock, creates effects |
| `scripts/weather/weather_effect.gd` | Base class for effects |
| `scripts/weather/effects/` | `grip`, `wind`, `rain`, `fog`, `lightning` effects |
| `tests/weather_test.gd` | Verification (registered in `tests/run_checks.py`) |

## Profiles

Fields: `id`, `label`, `tip`, `chance`, `multiplier`, `wind`, `gust`, `gust_every` (seconds, min/max), `gust_rise`, `grip` (friction scale), `fog` (0 to 1), `rain` (particle rate), `lightning_every` (seconds, min/max; zero disables), `warning` (seconds of rumble before a strike), `power_cut` (seconds). A zero or neutral value switches the matching effect off.

| Profile | Chance | Multiplier | Settings |
|---|---|---|---|
| clear | 0.30 | 1.0 | none |
| fog | 0.15 | 1.2 | fog 0.75 |
| wind | 0.20 | 1.3 | wind 60, gust 110 every 4 to 9 s, rise 1.0 s |
| rain | 0.20 | 1.3 | wind 12, grip 0.35, rain 160 |
| storm | 0.15 | 1.6 | wind 80, gust 150 every 4 to 8 s, rise 0.8 s, grip 0.35, rain 220, lightning every 12 to 25 s, warning 1.0 s, power cut 1.1 s |

`Weather.profiles()` lists `data/weather/` with `ResourceLoader.list_directory`, which follows export remaps, so adding a `.tres` adds a weather with no code change.

## Clock

`Weather` is a `Node` added to the round's world, so it pauses with the world. `configure(profile, seed)` seeds its generator and picks a wind side (`direction`, +1 or -1). Gusts wait a random interval, then `gust_level` rises linearly over `gust_rise`, holds 0.6 s and falls over `gust_rise`. `wind_now()` returns `direction x (wind + gust x gust_level)`, clamped to the optional symmetric `wind_cap`. Lightning emits `lightning_warning` `warning` seconds before a strike, then `lightning(x)` and `power_cut(seconds)`, and schedules the next.

## Effects

`Weather.EFFECTS` lists the effect scripts. `attach(context)` creates each one whose `applies(profile)` is true and calls `bind(weather, context)`. Adding a kind of effect is one file plus one line in that list.

- **grip:** multiplies each scrap body's own friction by `grip` once when the world is built.
- **wind:** each physics step, pushes the head with `wind x 1.04 x mass` (an acceleration of 1.04 per unit of wind, so a full gust swings it more than 6 degrees) and each body in `blown_bodies()` that has no contacts with `wind x width x height x 0.0008`, so a piece's drift is its size over its mass and light scrap drifts most. Thrown-back scrap is excluded for its whole flight (`SortingBin.is_thrown`). While the round runs it pushes the trolley along the rail by `wind x 0.22` units per second through `drift_crane(dx)`, so the player steers against it. It shows three faint ribbons (`wind_trails.gd`) on randomized smooth curves with 4.5s fading, narrowing path-history tails and flat vertical fronts and yard-edge fades. Seven dark-brown dust particles emit in one-shot bursts 6–11 seconds apart, above the floor, moving at 12–36 units/s with size/shade variation and lifetime fade. Cosmetic RNG is separate from weather rolls. It sets `ambience.wind` so clouds speed up, and drives the `wind_loop` level from `strength()`.
- **rain:** non-colliding `CPUParticles2D` streaks angled by `wind_now()`, floor splashes, a translucent sheen strip on the floor, and one soft rain loop selected by particle rate: slight (<100), normal (<200), or violent (≥200), at −22/−19/−16dB respectively. Only the selected loop runs; effect lifecycle handles pause/mute/rebuild.
- **fog:** a gradient overlay at z 6 whose alpha is 0 within 150 units of the trolley and reaches `fog x 0.85` at 650; bin labels dim to `1 - fog x 0.6`. Visual only.
- **lightning:** plays `thunder` quietly at the warning and loudly at the strike, flashes a white overlay and draws a fading bolt, and connects `power_cut` to the round.

## Context contract

The salvage round is the effects' context and provides: `layout`, `world`, `weather`, `trolley`, `ambience`, `sfx`, `round_state`, `bin_labels`, `drift_crane(dx)`, `scrap_bodies()` (valid scrap), `blown_bodies()` (the head plus scrap that is not held and not being thrown back), and `power_cut(seconds)`.

The round picks the weather when it builds its world, from `forced_weather` when set (tests) or from the [level catalog](levels.md); its gust/lightning seed is randomized. It passes the profile's multiplier to `round_state.configure`. `power_cut` affects the electrically powered head (magnet normally, claw in Blood Moon): it drops the load, shows the open frame and blocks pickup until `power_out_left` runs out in the round's physics step, which only runs while the round is running, so the cut freezes while paused. Fitting a head or rebuilding the world clears it. The other head is unaffected.

On Level 3 specifically, lightning instead inverts the actual magnet switch for 0.45s, releases the load when switching off, then restores its previous state. An initially OFF magnet becomes usable during the brief ON interval; restoration to OFF releases any caught load. Overlapping strikes extend the timer without another inversion. Pause freezes it; manual grip input, head swap, restart and results cancel pending restoration. The mechanical claw remains unaffected. Other levels retain the power-cut behavior above.

The HUD shows `weather_label()` ("Storm x1.6", or just "Clear") as a badge, the label and tip on the start card, and the weather bonus on the results card. See [round HUD](round_hud.md) and [sorting and rounds](round.md) for the multiplier.

## Intensity

`intensity` (0 to 1, default 1) is set by level events. `wind_now()` scales by it, so wind force, crane drift, trails and wind sound follow. Fog density and rain streak/splash alpha and loop level scale by it. Lightning does not count down below `STRIKE_INTENSITY` (0.8). Effects share looping-sound handling with other nodes through `scripts/audio/sound_loops.gd` (`loop_sound`).

## Verification

`tests/weather_test.gd` checks: every profile loads; seeded picking matches the chances within 2% over 10,000 rolls; clear has no wind or lightning; wind keeps its side and gusts within 12 s; the storm sequence is rumble, strike, power cut with the warning spacing; a disabled weather node stops its clock; forced weather, rain grip and the round multiplier; wind drifting an airborne piece downwind while grounded scrap stays and thrown-back scrap is exempt, showing direction-correct curved trails and sparse, slow, raised, fading dust, pushing an unsteered crane downwind and swinging the head more than 6 degrees within ten seconds; rain particles, fog density and dimmed labels, and no effects under clear; a power cut dropping a magnet's load, blocking pickup, freezing while paused, ending on a head change, sparing the claw and resetting on restart; the weather sounds existing and following the SFX toggle; and a full round under each weather finishing with its bonus and HUD badge. `tests/audio_test.gd` decodes the three new sounds with the rest. `tests/salvage_test.gd` forces clear to stay deterministic.

2026-09-25 validation: full `tests/run_checks.py` on Windows Godot 4.7; windowed screenshots of rain, fog, the storm start card and a strike checked. Hardware Gamescope captures and exported-build checks were not run.

## Limits

Wind acts on the head, not the cable itself (a massless constraint), and the drawn rope does not lean with it, because the rope solver takes no external force. Rain drops and splashes do not collide. Values are untuned starting points.

The later visual-only wind/dust pass passed the full managed Linux suite and hardware UI captures. See [wind/UI review](../docs/wind-ui-review.md); no weather balance or rain-particle settings changed.

Profiles additionally carry neutral-default `tint`, `direction_every`, `direction_transition` and `wind_cap`. Blood Moon uses these for [bounded direction cycles and tainted effects](levels.md); other weather retains its fixed side. The HUD displays Wind left/right or calm. Direction and generator timing pause with simulation.

Wind ribbons keep at most 144 history samples each, with an approximately 30Hz sample interval and quadratic age fade. Continuous signed direction controls horizontal motion; reversal preserves position/history rather than mirroring a ribbon. Each wrap randomizes curve phase, bend, frequency, head width and speed using cosmetic RNG. `tests/wind_motes_test.gd` checks direction, curve movement, stationary calm, continuous reversal, age fade, wrap variation and bounded storage.

Wind-mote validation: full managed engine suite passed, including `WIND_MOTES_TEST_OK`, existing weather physics and Blood Moon reversal checks. Silent hardware captures checked dot/tail movement on Breezy and Blood Moon; see `.local/motes-light-review/`.

`tests/lightning_flicker_test.gd` exercises real Level 3 signal wiring, switch/HUD inversion, dropped load, restoration in both directions, overlap, pause and manual/head/restart cancellation. Rain tier boundaries are checked independently from presentation.

Lightning/rain validation: complete managed Godot 4.7 suite passed after rebasing onto `826efb6`, including `LIGHTNING_FLICKER_TEST_OK` and unchanged Blood Moon power-cut regressions. Audio waveform and real muted-mixer evidence is recorded in [audio](audio.md).

Wind ribbon rendering: front width 4–5.5 units, narrowing continuously to zero at age 4.5s. Front cross-section is vertical and matches the adjacent tail width. Opacity is 0.055–0.12 by strength; transparent 0.7-unit edge strips soften each indexed ribbon mesh. A faint 0.8-unit vertical leading stroke replaces the circle. One mesh per trail bounds draw calls even with longer history. Tests cover monotonic taper, matched head width, alpha cap and valid indices in addition to motion/reversal/history bounds.

The whole ribbon also fades with its head at the yard boundary, so wrapping cannot suddenly remove a long visible tail.

Tapered-wind validation: full managed Godot 4.7 suite passed. After the final whole-ribbon edge-fade refinement, the focused wind regression and silent hardware captures passed on NVIDIA RTX 2080 Ti Compatibility, covering Breezy, Violent and Blood Moon plus direction reversals. Evidence: `.local/wind-ribbon-review/`.

Rebase verification against skyline fix `5036ebd`: wind and level regressions, the hardware skyline-render test, and all three weather/reversal captures passed again.
