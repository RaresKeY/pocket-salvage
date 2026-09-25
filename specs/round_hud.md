# Round HUD

Reviewed: 2026-09-25. Implementation revision: `53982f2` (source UI/wind pass; not in published v0.1.6).

## Ownership and contract

`scripts/ui/round_hud.gd` is a presentation-only full-rect `Control`. Mount it in a `CanvasLayer` above gameplay. It uses the shared `scripts/ui/yard_theme.gd` square theme and bundled Tiny5 font, reads no game nodes, handles no game shortcuts, and processes while the tree is paused.

`present(data: Dictionary)` accepts:

- `state`: `ready`, `running`, `paused` or `finished`.
- `score`, `time_left` (seconds, shown as a nonnegative ceiling in m:ss), `correct`, `wrong`, `total`, `delivered` (correctly sorted).
- `grip_label`: the fitted head and its state, such as "Claw READY"; falls back to Magnet ON/OFF from `magnet_on`.
- `music_on`, `effects_on`: independent text-labeled audio toggle states; `music_volume`, `effects_volume`: normalized session volume levels.
- `held_material`, `feedback`, `finish_reason`, `time_bonus` (added to results when positive), `weather_label` (a one-line top-bar badge, hidden when absent), `weather_tip` (start card: one line "label: tip"; below 420 px tall only the label is prefixed to the card's first line so Start stays on screen), `weather_bonus` (a results line after the label when positive), `navigation_hint` (appended to the controls footer).

Missing fields use empty/zero defaults and `ready`; a call before readiness is buffered. Score, time and sorted counts occupy separate aligned columns with thin dividers. While running at `HURRY_SECONDS` (10) or less the time turns `HURRY_COLOR` and pulses. The compact footer lists A/D move, W/S lift, Space grip, E swap, P pause and R restart. Music’s tooltip names the M shortcut. Long feedback wraps and grows the bottom inset.

Signals: `start_requested`, `restart_requested`, `pause_requested`, `music_requested`, `effects_requested`, `volume_requested`, `debug_requested`, and `layout_changed`; the caller chooses transitions. The HUD never keeps score, ticks the clock, pauses physics or decides outcomes.

A wrapping header holds score, time, sorted count, Music/SFX toggles and Pause. Head/load status and weather occupy a second top row; feedback and short hints remain in the compact footer. The playable yard fits between measured panel bounds with 6px clearance instead of fixed insets. Ready, paused and finished use a dimmed 460px modal with one focused action; entering running releases HUD focus. Audio toggles stay above the modal in all states and release focus after activation while running so Space still controls the crane. Decorative controls ignore the mouse. A small lower-right label shows `application/config/version` over every state.

## Lab and verification

`labs/hud/lab.tscn` proves the module with synthetic data: 1 ready, 2 running, 3 paused, 4 finished; P toggles pause, R returns to ready. `--capture PATH --state STATE` supports automated hardware captures. `tests/hud_test.gd` checks buffered presentation, counters, modal states, real mouse activation of start/pause/resume/replay, focus release and action bounds at 768×480, 854×480, 960×540, 1280×720 and 1920×1080. The salvage test checks the grip label and time-bonus results line. Headless checks prove behaviour, not rendering.

The HUD tests cover audio buttons above the ready modal, focus return, on/off labels, negative score and hurry-timer state. Hardware comparison and audio evidence: [v0.1.1 review](../docs/audio-ui-review.md).

## Controller and phone layout

`control_scheme` selects keyboard, gamepad or touch hints. `touch_enabled`, configured before readiness, adds `touch_controller.gd` to the footer’s right edge; gameplay enables it only while running. The footer changes to a vertical stack below 600 logical pixels, keeping controls right-aligned below feedback. The header uses a flow container, and the modal width is bounded by the current viewport. Direction/action targets are at least 44×44 CSS pixels on mobile Web. Root resize clears touch ownership even when the control’s own size stays unchanged. No controller art pack or second theme is introduced.

On touch landscape screens shorter than 540 logical pixels, the controller occupies a separate bottom-right panel and the yard/footer reserve a right-side column. The redundant touch hints are hidden there to give the yard more height. Portrait and taller layouts keep the controller in the footer. This follows the same theme and leaves game rules unchanged.

Direction buttons draw their arrows with canvas lines instead of font glyphs: exported Web fonts do not include Unicode arrows. The input regression test checks font-independent direction rendering; exported-browser screenshots verify the visible result.

HUD presentation compares snapshots after rounding the remaining time to its displayed second. Unchanged values skip label/button/theme rebuilding; the hurry alpha is still updated on every presentation. Ready buffering and state transitions remain immediate. The playable physics loop advances feedback before ticking the round and uses its changed signal for one HUD refresh per tick.

Resizing clears the displayed-value cache and re-presents the last data, so text that depends on screen size (the weather line) is rebuilt even when the game sends nothing new, as on the start card.

Developer controls (reviewed 2026-09-25 against the source change based on `04feb18`; not in v0.1.6): native source runs expose a collapsed Developer options section only while paused. Hitbox/mask CheckButtons emit `debug_requested`; HUD presentation stays independent of world traversal. Normal HUD instances and exported builds do not enable this section.

Verification: full managed engine suite passed in an isolated source copy, and hardware Gamescope captures on NVIDIA RTX 2080 Ti checked the expanded pause controls at 1920×1080, 1280×720, 960×540, 854×480 and 640×360 with Dummy audio. The final focused diagnostic test also covers new collision nodes while enabled. Export visibility is enforced by the source-run gate; no new release is created for this change.

The top panel separates aligned score/time/sorted counters, audio/pause actions and head/weather status. Controls wrap as a group below counters under 760px. Pause has independent 0–100% Music/SFX sliders; `volume_requested` carries normalized values and `present` synchronizes them without feedback signals. Existing quick mute buttons remain. Local Developer options temporarily replaces the slider rows when expanded. The font and square styles are shared with touch controls, bin labels and score popups.

The square theme, weather-visual refresh and volume-control verification are recorded in [the wind/UI review](../docs/wind-ui-review.md).
