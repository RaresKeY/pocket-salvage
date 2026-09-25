# Level selection

Reviewed: 2026-09-25. Implementation: level-grid change based on `eba13f6`.

`scripts/level/level_catalog.gd` owns twelve slots and three unlocked profiles. Level 1 reuses `data/weather/clear.tres` with no effects. Levels 2 and 3 use `data/levels/breezy.tres` and `violent.tres`; both enable all five existing effects with increasing intensity. Original weighted weather resources/API remain available to labs and tests.

The playable scene starts at level 1 in the ready grid. Selection is accepted only while ready and only for unlocked indexes. Rebuilding uses the selected profile unless the test-only `forced_weather` override is set. Replay retains selection; Levels on pause/results returns to ready. No unlock persistence exists. Geometry, controls, scoring rules and timer remain shared.

HUD `level_menu` enables the grid and Levels action; `selected_level` selects the tile. `level_selected(index)` and `levels_requested` delegate transitions to the scene. Twelve minimum-44px tiles use six columns, four below 500px. Locked tiles are disabled and labeled LOCKED. Mouse/touch and controller direction selection are supported.

Verification: `tests/level_selection_test.gd` checks locked guards, ready-only selection, all effect profiles, replay, pause/results return, controller commands, and grid/action bounds at seven desktop/phone sizes. Registered in the full engine suite.

Validation: full managed Godot 4.7 suite passed after the final layout fix (`CHECKS_OK`). Six-size Gamescope hardware captures used NVIDIA RTX 2080 Ti and Dummy audio, including 640×360 and 390×844. Local evidence: `.local/level-grid/`. Native tests assert bounds down to 320×568; no new Web release was produced.
