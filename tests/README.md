# Verification

Run `./tests/check` from the repository root on the shared workstation. The script only orchestrates the managed Godot Podman runner; engine execution happens inside one ephemeral managed container. It resolves a sibling `godot-podman` checkout or the `GODOT_PODMAN_RUNNER` override, preserves the hardware-access default, and opens no desktop window.

`run_checks.py` imports the project, verifies exact pixel blocks and alpha, exercises the scaling CLI and provenance, tests lab controls, and runs a two-frame startup. It bounds child processes and rejects logged script errors or missing success markers. Headless checks are not visual/hardware-renderer proof. Other environments can use the equivalent suite in [README.md](../README.md), subject to their local execution rules.

Use [the background capture flow](../labs/pixel_scaling/README.md) for hardware-rendered comparisons. Its image metadata records when an on-screen native-integer/baked comparison was actually checked; offscreen pairs are not counted as proof.

`rope_test.gd` checks actual slack, tension and wrapped-route behavior as well as renderer isolation. The suite also runs the rope lab for 120 physics ticks. Use `./labs/capture rope` for its separate hardware-rendered check. Refer to tests and input files with project-relative paths, so records remain useful across machines and worktree lanes. The combined timed-round test is described below.

`physics_parts_test.gd` checks real ray hits, filtered Area2D overlap, private shape ownership, independently enabled parts, and visual-mask material lifetime. The physics lab startup is also checked. `./labs/capture physics` verifies rendered alpha and observes contacts/sensors on the GPU. Its boxes are diagnostic fixtures, not game object definitions.

`sprite_playground_test.gd` verifies all 123 exact 8× derivatives and provenance, the 41-tile gallery, gravity/floor collision, matching sprite/collision size, filtering, mouse picking/grab/release and reset. `./labs/capture sprite_playground` supplies separate GPU captures.

`yard_camera_test.gd` checks the scene’s enlarged texture bindings, tile regions, native viewport, smooth pointer-anchored zoom, limits, left/middle panning, release/focus cancellation, reset and resize.

`crane_test.gd`, `round_test.gd`, `hud_test.gd` and `level_test.gd` cover the independent subsystems. `salvage_test.gd` drives a ten-piece real-physics round through the combined lab, including a deliberate wrong sort, the magnet refusing copper and rubber and a head swap at the stands, then checks carrying pause, end-state, restart, motor sounds, music mute and timeout release. `weather_test.gd` checks weather profiles, weighted picking, the gust and lightning clock, each effect, power cuts and a full round under every weather ([spec](../specs/weather.md)). `ambience_test.gd` checks gull perching, crane scares, departures, uneven flight and the spawn cap. This proves deterministic playability, not human enjoyment.

`physical_suspension_test.gd` verifies rigid-body pivot tilt, angular stops, inertial lag, slack tension, load feedback and cable draw order. Rope tests separately retain moving/reeling history through taut-to-slack transitions.

`rope_interpolation_test.gd` samples render frames between physics ticks and checks endpoint interpolation, physics-history isolation, pause and reset. `python3 tests/test_release.py` tests release version/ancestry guards, candidate identity, payload integrity and ZIP/payload agreement without engine execution or network. Main pushes run it plus the full engine suite; stable tags additionally build and publish. Reproducible exports are verified separately with `python3 tools/build/build_all.py --verify`.

`audio_test.gd` decodes every cue, checks independent SFX/music control and the audio lab. Optional `--require-pulse` validates each cue against actual mixer frames with Master muted downstream. HUD checks cover audio buttons, focus return and hurry-timer state. See [audio](../specs/audio.md).

`input_test.gd` exercises standard gamepad events through Godot’s real input path, analog deadzone and actual crane movement, discrete commands, disconnect/focus recovery, simultaneous touch direction/grip, drag/cancel/release, rotation and phone layouts down to 320×568. The suite uses `--touch-controls` only for this diagnostic; normal visibility is automatic on mobile Web. Physical controller/phone playtests are separate.

`level_selection_test.gd` covers the grid and locked slots. `level_progression_test.gd` checks configured startup, all four pile recipes and material coverage, Victory → Continue → selection, final-level bounds and timeout Retry/Levels. `blood_moon_test.gd` checks reversed pickup, random bounded weather, smooth wind transitions, generator outages, pause and reset isolation. The ten-piece physics regression uses level 3 with explicit Clear weather.

`wind_motes_test.gd` verifies curved motion, continuous wind reversal and bounded fading-tail history. `test_launcher.py` uses silent stubs to verify fresh local files, symlink launches and import failure handling. `blood_lighting_render_test.gd` is a separate hardware-rendering check: run with the managed runner under headless Gamescope and `--audio-driver Dummy`; it compares bulb, pole and beacon-housing pixels and verifies lens-only power dimming. It is not part of the headless engine suite. `skyline_render_test.gd` is the same kind of check: it renders the backdrop and asserts every stretch of the horizon shows skyline for both sets, which catches mirrored tiles going missing (a negative-width draw rect is silently skipped).

`lightning_flicker_test.gd` verifies Level 3 inverse/restore behavior, load drop, HUD state, pause, overlap, manual override, head swap/restart and rain tier selection. `test_rain_audio.py` verifies seeded PCM reproducibility, softness bounds, increasing intensity and seamless endpoints; engine audio checks decode all three rain tiers.
