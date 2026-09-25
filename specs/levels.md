# Level selection

Reviewed: 2026-09-25. Implementation: lightning/rain change based on `826efb6`.

`scripts/level/level_catalog.gd` owns twelve slots and four unlocked profiles. Level 1 reuses `data/weather/clear.tres` with no effects. Levels 2 and 3 use `data/levels/breezy.tres` and `violent.tres`; both enable all five existing effects with increasing intensity. Original weighted weather resources/API remain available to labs and tests.

`project.godot`, source launcher and exports all open the playable scene at level 1 in the ready grid. Selection is accepted only while ready and only for unlocked indexes. Rebuilding uses the selected profile unless the test-only `forced_weather` override is set. Explicit restart retains selection. A win shows Victory with score/bonuses and Continue; Continue returns to the grid and highlights the next unlocked level (or stays on level 4 after its win). Timeout offers Retry plus Levels; pause offers Levels. Blood Moon (slot 4) uses a fresh randomized profile from `roll_weather`; slots 5–12 remain locked. No unlock persistence exists. Geometry, controls, scoring rules and timer remain shared.

HUD `level_menu` enables the grid and Levels action; `selected_level` selects the tile. `level_selected(index)` and `levels_requested` delegate transitions to the scene. Twelve minimum-44px tiles use six columns, four below 500px. Locked tiles are disabled and labeled LOCKED. Mouse/touch and controller direction selection are supported.

Verification: `tests/level_selection_test.gd` checks locked guards, ready-only selection, all effect profiles, replay, pause/results return, controller commands, and grid/action bounds at seven desktop/phone sizes. Registered in the full engine suite.

Validation: full managed Godot 4.7 suite passed after the final layout fix (`CHECKS_OK`). Six-size Gamescope hardware captures used NVIDIA RTX 2080 Ti and Dummy audio, including 640×360 and 390×844. Local evidence: `.local/level-grid/`. Native tests assert bounds down to 320×568; no new Web release was produced.

## Blood Moon

`scripts/level/blood_moon.gd` owns generator timing and pauses with the round. After 18–32s the right lamp stutters for 1.6s; a 2–4s outage stops new generator smoke, turns off floodlight cones and cuts the electrically powered head, then recovers. `yard_ambience.gd` receives a Blood Moon flag before constructing scenery: the generated `backdrop_blood_moon` in place of the moon, crimson clouds/beacon lenses/light cones, red sky and crows only (no gull or rat spawns). Weather nodes use the profile tint, including rain/splashes/sheen, fog, trails/dust and lightning.

`Heads.function_kind/materials/grips/for_material` accept a reversal flag. In Blood Moon the magnet lifts copper/rubber and the claw lifts steel; power cuts affect the claw. Existing physical head art/animations and sounds retain their identities. Pickup stays blocked throughout an outage even after a head swap. Hints and start feedback use the reversed mapping. Leaving/rebuilding destroys all special state.

Weather rolls: base wind 16–40, gust 18–40, rain 45–120, fog 0.1–0.28, grip 0.55–0.85; multiplier 1.5. Wind begins on a random side, holds for 8–18s, transitions for 3s, then holds on the opposite side; normalized direction is clamped to ±1 and force to ±80. The HUD names current wind direction, including calm near zero.

Verification: `tests/blood_moon_test.gd` covers independent bounded rolls, head mapping, animal exclusion, smooth wind crossing/caps, lamp stutter/outage/recovery, pause and return to Clear.

Blood Moon validation: full managed Godot 4.7 suite passed (`CHECKS_OK`); the subsequent focused test passed real pickup/refusal through both reversed heads. Hardware Gamescope captures on RTX 2080 Ti checked ready, running and outage at 1280×720, 640×360 and 390×844 with Dummy audio. Evidence is local under `.local/blood-moon/`. No new hosted build was published.

## Pile progression and flow verification

Catalog counts are 4, 6, 10 and 12. Layout uses per-count non-overlapping row recipes, all three materials and the existing deterministic jitter/physical settling. Ready details show the selected count. `tests/level_progression_test.gd` checks every count/variant for bounds, material coverage and overlap; all four victories precede grid navigation; button/controller Continue, final-level selection, timeout Retry/Levels and result bounds are covered. Startup navigation reads the configured main scene. The full physics bot retains its original ten-piece test on level 3 with explicit Clear weather.

World rebuilds clear transient feedback so a previous level’s tool/power messages cannot linger on the next selection screen.

Level-flow validation: full managed Godot 4.7 suite passed, including the original ten-piece physics completion in 170.05 simulated seconds. Focused progression checks passed after clearing stale transition feedback. Silent RTX 2080 Ti/Gamescope captures checked opening, victory, next selection and final victory at 1280×720, 960×540, 854×480, 640×360 and 390×844. Local evidence: `.local/level-progression/`. No release/deployment was created.

Blood Moon lighting uses `shaders/blood_moon_bulbs.gdshader`: bounded lens regions and lens colors restrict strong red emission/dimming to bulbs, preserving metal RGB and source alpha. `blood_moon_grade.gdshader` on the yard viewport container applies a 5% red screen wash plus up to 5% edge tint; HUD and menus stay ungraded. Rebuild clears the material outside level 4. `tests/blood_lighting_render_test.gd` needs real rendering and verifies pole/housing pixel preservation, red bulbs and power-off dimming on floodlight and bright/dim beacon frames.

Lighting refinement validation: full managed Godot 4.7 suite passed; silent RTX 2080 Ti/Gamescope rendering passed `BULB_MASK_GPU_OK` for floodlight and bright/dim beacon frames, plus Blood Moon material-reset checks. Captures include running wind motes and generator outage. Local evidence: `.local/motes-light-review/`.

Blood Moon also swaps the backdrop's `skyline` to `backdrop_blood_skyline_tile` (a generated crimson skyline); `yard_backdrop.gd` exposes `skyline` for that. `tests/blood_moon_test.gd` checks the Blood Moon moon and skyline and that Clear restores both.

Violent (Level 3) lightning briefly inverts the magnet for 0.45s before restoring its previous switch state; see [weather](weather.md). Its rain uses the violent soft-audio tier; Breezy uses slight and Blood Moon selects slight/normal from its randomized rain strength.
