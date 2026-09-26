# Player input

Reviewed: 2026-09-26. Implementation: landscape HUD change in this commit, based on `0fa2f34`.

`scripts/input/crane_motion.gd` owns normalized analog input, the 0.2 radial gamepad deadzone (rescaled to 0–1), and bounded crane speeds (220 horizontal / 130 reel units per second). Touch has zero deadzone. Keyboard/D-pad axes use full speed; strongest source wins each axis instead of adding devices. `salvage_input.gd` owns digital actions, active-stick events and device-neutral commands. `move_crane` also clamps inputs at the integration boundary.

Standard gamepad buttons: A/south primary or grip; X/west swap; Y/north restart; Start contextual menu; B/east pause/resume; LB music; RB SFX. The adapter consumes gamepad buttons before GUI focus handling so a single press cannot both start and grip, or operate a focused audio button instead. Modal confirmation has one primary action; bumpers expose audio without navigating GUI focus. Keyboard commands remain unhandled-key events so focused native buttons keep their established behavior. Scene-changing commands mark the event handled before emitting to avoid reading a freed viewport.

Movement is enabled only while running. Pause/focus loss/restart clear virtual input and require physical movement to return to neutral before it can drive the crane again. Active-controller disconnection pauses controller play; keyboard/touch remain available afterward. Project settings suppress physical gamepad events while unfocused.

Mobile touch detection uses Web Android/iOS feature tags, with a user-agent/iPadOS touch fallback for desktop-site mode. Native/desktop Web do not automatically show touch controls. `--touch-controls` forces the presentation for diagnostics. On mobile Web, the root window’s content scale equals backing-pixel width divided by canvas CSS width, preserving logical button sizes on high-DPI screens.

`scripts/ui/touch_controller.gd` is a full-screen overlay: rounded analog stick at bottom right and diagonal Grip/Swap circles on the left. One finger owns the stick through off-ring drags, with strength capped at 1; independent action fingers trigger once on press. Release/cancel, pause, focus loss and resize clear ownership. Smooth generated icon provenance: [prompts](../prompts/image/mobile-controls.md). Targets are 60px and the stick diameter is 112px. Controls draw only while running and reserve no world column/footer. Touch feedback moves into the header; the yard preserves aspect ratio behind the controls. In landscape touch mode the header overlays the full-screen stage; its text is larger and outlined, and Music/SFX move out of the running row but remain available in Pause. Rotation restores the regular portrait panel and clears touch ownership.

`play-mobile.sh` invokes current local `play.sh` with 844×390 resolution, `--touch-controls` and `--mobile-preview`; the latter enables real-mouse dragging without handling emulated mouse events twice. It never fetches source. Native downloads and Web still support physical gamepads; the container launcher does not forward host gamepad devices.

`fullscreen_control.gd` adds a top-right 44px fullscreen button. Native preview toggles window mode; Web installs a DOM button so the request stays inside the trusted click gesture. Standard and WebKit-prefixed APIs are capability-detected; failure displays browser-menu/Home-Screen guidance. Browser policy and embedded-page permissions can still deny fullscreen. Aspect fitting runs after resize. See [Fullscreen API](https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API).

Verification is recorded in [mobile overlay review](../docs/mobile-overlay-review.md). Tests cover real analog motion, zero-deadzone touch, saturation, simultaneous grip, interruption/rotation, and seven viewport sizes. Physical phone/controller compatibility requires real devices.

While paused, D-pad up/down selects Resume, volume sliders or local Developer controls; left/right changes a focused slider by 5 percentage points. A activates the focused button; B/Start still resumes directly. Running D-pad motion remains unchanged. These directions travel through explicit settings commands rather than implicit GUI navigation.

F2 has no command mapping. The game has no preview scene-switch handler or preview hint; `play.sh` inherits this same source behavior. Navigation tests press F2 in ready, running, paused and finished states and verify the scene/state remains unchanged.

Validation: full managed Godot 4.7 engine suite passed (`CHECKS_OK`), including real F2 key events in all four states. Silent hardware captures refreshed the README images without the old hint. Evidence: `.local/no-preview-review/`.

Landscape HUD verification: see the 2026-09-26 follow-up in [mobile overlay review](../docs/mobile-overlay-review.md), including nine viewport sizes, dense counters, orientation/state transitions and native GPU evidence.

Tables (2026-09-26 tidy): `salvage_input.gd` `DIRECTION_BINDINGS` maps each movement action to its keys and D-pad button; `touch_controller.gd` `BUTTONS` maps each touch command to its icon and centre from the bottom-left corner, so a new button is one entry.
