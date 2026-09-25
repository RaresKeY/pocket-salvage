# Round HUD

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`.

## Ownership and contract

`scripts/ui/round_hud.gd` is a presentation-only full-rect `Control`. Mount it in a `CanvasLayer` above gameplay. It shares the art lab theme, reads no game nodes, handles no game shortcuts, and processes while the tree is paused.

`present(data: Dictionary)` accepts:

- `state`: `ready`, `running`, `paused` or `finished`.
- `score`, `time_left` (seconds, shown as a nonnegative ceiling in m:ss), `correct`, `wrong`, `total`, `delivered` (correctly sorted).
- `grip_label`: the fitted head and its state, such as "Claw READY"; falls back to Magnet ON/OFF from `magnet_on`.
- `held_material`, `feedback`, `finish_reason`, `time_bonus` (added to results when positive), `navigation_hint` (appended to the controls footer).

Missing fields use empty/zero defaults and `ready`; a call before readiness is buffered. Score and time carry the contributed coin and timer icons. While running at `HURRY_SECONDS` (10) or less the time turns `HURRY_COLOR` and pulses. The footer lists A/D move, W/S raise/lower, Space grip, E swap head at a stand, P pause, R restart and M music. Long feedback wraps and grows the bottom inset.

Signals: `start_requested`, `restart_requested` and `pause_requested`; the caller chooses transitions. The HUD never keeps score, ticks the clock, pauses physics or decides outcomes.

Top status and bottom hints leave the centre clear, fitting a 100px top / 121px bottom gameplay inset at the 768×480 minimum with one-line feedback. Ready, paused and finished use a dimmed 500px modal with one focused action; entering running releases HUD focus. Decorative controls ignore the mouse. A small lower-right label shows `application/config/version` over every state.

## Lab and verification

`labs/hud/lab.tscn` proves the module with synthetic data: 1 ready, 2 running, 3 paused, 4 finished; P toggles pause, R returns to ready. `--capture PATH --state STATE` supports automated hardware captures. `tests/hud_test.gd` checks buffered presentation, counters, modal states, real mouse activation of start/pause/resume/replay, focus release and action bounds at 768×480 and 1280×720. The salvage test checks the grip label and time-bonus results line. Headless checks prove behaviour, not rendering.
