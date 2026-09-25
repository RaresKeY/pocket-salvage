# Player input

Reviewed: 2026-09-25. Implementation revision: `53982f2` (source UI/wind pass; not in published v0.1.6).

`scripts/input/salvage_input.gd` owns four `salvage_*` movement actions and device-neutral command signals. WASD/arrows, standard D-pad and left-stick axes share the action map with deadzone 0.2. Horizontal and reel axes remain independent, clamped to [-1, 1]; stick strength preserves proportional movement. Existing crane speeds, bounds and grip/stand rules are unchanged.

Standard gamepad buttons: A/south primary or grip; X/west swap; Y/north restart; Start contextual menu; B/east pause/resume; LB music; RB SFX. The adapter consumes gamepad buttons before GUI focus handling so a single press cannot both start and grip, or operate a focused audio button instead. Modal confirmation has one primary action; bumpers expose audio without navigating GUI focus. Keyboard commands remain unhandled-key events so focused native buttons keep their established behavior. Scene-changing commands mark the event handled before emitting to avoid reading a freed viewport.

Movement is enabled only while running. Pause/focus loss/restart clear virtual input and require physical movement to return to neutral before it can drive the crane again. Active-controller disconnection pauses controller play; keyboard/touch remain available afterward. Project settings suppress physical gamepad events while unfocused.

Mobile touch detection uses Web Android/iOS feature tags, with a user-agent/iPadOS touch fallback for desktop-site mode. Native/desktop Web do not automatically show touch controls. `--touch-controls` forces the presentation for diagnostics. On mobile Web, the root window’s content scale equals backing-pixel width divided by canvas CSS width, preserving logical button sizes on high-DPI screens.

`scripts/ui/touch_controller.gd` is a presentation/input `HBoxContainer` inheriting the existing HUD theme. A three-by-three directional grid and Grip/Swap column sit at the bottom right. Each finger owns a button; unique held directions determine the vector, allowing opposite directions to cancel and duplicate fingers to avoid double speed. Actions trigger once on press. Dragging off a direction releases it, while release/cancel works outside the original button. Pause/results, focus loss and root resize clear all ownership. Decorative controls ignore emulated mouse events, avoiding duplicate grip actions. The regular HUD buttons still support touch through Godot’s mouse emulation.

`labs/salvage/lab.gd` consumes the movement vector and commands; the HUD reads `control_scheme` for hints. The HUD’s flow header, bounded modal and responsive footer support desktop and portrait/landscape phone sizes without overlapping the yard. See [HUD](round_hud.md).

Verification: `tests/input_test.gd` injects real Godot joypad/touch events and checks actual trolley movement, analog deadzone, each command, focus/disconnect neutral gating, simultaneous three-finger movement/reel/grip, release/cancel/drag, pause and rotation. It checks touch targets and modal/yard bounds at 320×568, 390×844, 844×390, 854×480, 960×540, 1280×720 and 1920×1080. This does not establish physical controller or phone compatibility; those require real devices. `play.sh` forwards display/audio through the managed container but does not forward host gamepad devices; use native downloads or Web for physical-gamepad testing.

On touch landscape screens shorter than 540 logical pixels, the controller occupies a separate bottom-right panel and the yard/footer reserve a right-side column. The redundant touch hints are hidden there to give the yard more height. Portrait and taller layouts keep the controller in the footer. This follows the same theme and leaves game rules unchanged.

Local preflight: the full managed Godot test suite and eight offline release-contract tests passed. The input suite additionally guards against the header covering the modal title and verifies the short-landscape controller panel cannot overlap the yard. The rebuilt Web package passed Firefox touch/gamepad checks with no game-console errors; Android and iPadOS identities at DPR 3 exercised automatic detection and responsive layout. See [review and limits](../docs/input-review.md).

Direction buttons draw their arrows with canvas lines instead of font glyphs: exported Web fonts do not include Unicode arrows. The input regression test checks font-independent direction rendering; exported-browser screenshots verify the visible result.

While paused, D-pad up/down selects Resume, volume sliders or local Developer controls; left/right changes a focused slider by 5 percentage points. A activates the focused button; B/Start still resumes directly. Running D-pad motion remains unchanged. These directions travel through explicit settings commands rather than implicit GUI navigation.
