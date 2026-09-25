# Round HUD

Reviewed: 2026-09-24 alongside the initial HUD implementation.

## Ownership and contract

`scripts/ui/round_hud.gd` is a presentation-only full-rect `Control`. Mount it in a `CanvasLayer` above gameplay. It shares the existing art lab theme; it neither reads game nodes nor handles game shortcuts. It processes while the tree is paused.

`present(data: Dictionary)` accepts `state` (`ready`, `running`, `paused`, `finished`), `score`, `time_left` (seconds), `correct`, `wrong`, `total`, `delivered` (correctly sorted), `time_bonus` (shown on results when positive), `magnet_on`, `held_material`, `feedback`, and `finish_reason`. Missing fields use empty/zero defaults and `ready`; a call before readiness is buffered. Time displays a nonnegative ceiling in minutes and seconds. The caller supplies human-readable finish reasons. Keep feedback concise: long text wraps and increases the bottom inset.

Signals: `start_requested`, `restart_requested`, and `pause_requested`. The paused Resume button emits `pause_requested`; the caller chooses the transition. The HUD does not maintain scores, tick the clock, pause physics, or choose round outcomes.

Top status and bottom hints leave the center clear during running. At the minimum 768×480 window with ordinary one-line feedback the top ends at y95 and bottom begins at y373, fitting a gameplay inset of 100px top / 121px bottom. Ready/paused/finished use a dimmed modal and focused action. Entering running releases HUD focus so ordinary game keys are available. Decorative controls ignore mouse input; buttons and the active modal receive it. Native Control/container layout resizes independently of world zoom.

## Lab and verification

`labs/hud/lab.tscn` proves the module with synthetic data: 1 ready, 2 running, 3 paused, 4 finished; P toggles pause, R returns to ready. These are lab shortcuts, not module shortcuts. `--capture PATH --state STATE` supports automated hardware captures.

`tests/hud_test.gd` checks buffered presentation, counters, modal states, actual mouse activation of start/pause/resume/replay, focus release and action bounds at 768×480 and 1280×720. Headless checks prove behavior, not hardware rendering. Visual checks use the shared runner under Gamescope headless and inspect screenshots.

Optional `navigation_hint` appends caller-owned navigation guidance to the controls footer; the playable integration uses F2 preview.

The small lower-right version label reads `application/config/version`, remains visible over modal states, and ignores mouse input. The footer reserves 28px beneath its panel for the label.
