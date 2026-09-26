# Mobile overlay review — 2026-09-25

Implementation rebased onto `285719e` (latest Blood Moon art), with [RaresKeY’s requested direction](../prompts/source/mobile-overlay.md). Generated icons use the built-in imagegen tool; exact [prompts and assets](../prompts/image/mobile-controls.md) are committed.

## Implemented

- `play-mobile.sh`: current local source at 844×390, touch overlay forced, real mouse drag as a preview finger.
- Right analog circle and two diagonal left action circles over the yard; no reserved controller column/footer. Generated pale-gray smooth Grip/Swap icons, independent of the pixel HUD font.
- Shared bounded movement: keyboard/D-pad full per-axis speed, analog strength 0–1, rescaled 20% radial gamepad deadzone, no touch deadzone, no additive device speed boost. Crane and motor loops share the same speed constants.
- Top-right fullscreen control; native window toggle and Web synchronous DOM click request with standard/WebKit capability checks, denial guidance and aspect-preserving resize.

## Verification

After rebasing onto the latest Blood Moon art, the full managed Godot 4.7 suite passed (`CHECKS_OK`), including real controller input, trolley movement, analog saturation, tiny touch deflection, simultaneous grip, off-ring drag/release, pause/focus/disconnect cancellation, rotation, mouse preview, modal bounds and seven viewport sizes. Two offline launcher tests passed, including argument forwarding and fresh-source/import-failure behavior.

Silent native hardware captures used Gamescope headless plus the managed runner: NVIDIA RTX 2080 Ti, Compatibility OpenGL, Dummy audio. Reviewed ready/running/pause at 320×568, 390×844, 844×390 and 1280×720. The first 320px pass exposed a header/fullscreen collision; narrower text and a clearance regression assertion fixed it. Aspect-preserved portrait play necessarily leaves vertical spare space; landscape provides a larger yard.

Web export passed. Firefox loaded the actual exported candidate with an Android user-agent override at 844×390 and 390×844, showing the overlay and generated icons with no game-console errors. A real BiDi click supplied transient user activation, but this headless Gamescope Firefox window reported `document.hasFocus() == false`; its native fullscreen request was denied. The visible fallback passed. Explicit rejection and a mocked WebKit-prefixed dispatch also passed; this is not proof of WebKit/iOS fullscreen. Successful fullscreen entry remains unverified in this harness. DOM activation returns focus to the canvas so subsequent Space presses continue controlling the game. Evidence is in ignored `.local/mobile-review/`; exported payloads are temporary. No physical Android/iOS or gamepad hardware claim is made. Browser API policy may prevent fullscreen, especially when embedded without permission.

## Landscape HUD follow-up — 2026-09-26

User direction: [larger outlined HUD over the mobile landscape game](../prompts/source/mobile-overlay.md). Implementation follows `0fa2f34`; inferred sizes and presentation choices live in [HUD design](../design/round_hud.md).

### Scope and findings

The old solid header left a 275px yard at 844×390 and 210px at 640×360. Small status text and audio controls competed with the counters. Short landscape menus could overlap their titles; wrapped feedback could leave unused header height after a state change.

### Changes

Landscape touch play uses larger Tiny5 counters/status/feedback with dark outlines and no header surface or separators. Pause is 80×52; Music/SFX toggles and sliders remain accessible in Pause. The yard uses the whole viewport, retains aspect ratio and keeps its scale during menu transitions. At 844×390 its rendered height grows from 275px to 337.6px (about 23%); at 640×360 it grows from 210px to 256px (about 22%). Landscape menus use a compact single row on narrow screens and hide transient feedback. Header height shrinks with content, and compact mobile counter spacing preserves fullscreen clearance with four-digit scores. Portrait keeps its existing panel layout, and desktop retains its regular fonts/actions. Gameplay, art, thumb control sizes and input mappings are unchanged.

### Verification

Native Gamescope headless captures through the managed Godot runner cover ready/running/paused/finished states at 568×320, 640×360, 844×390, 854×480, 960×540, 1280×720, 1920×1080, 390×844 and 320×568, with a separate desktop presentation pass. GPU renderer: NVIDIA RTX 2080 Ti Compatibility, Dummy audio. Matched before/after evidence is retained in ignored `.local/mobile-landscape/`; dense 568×320 and 844×390 captures include a four-digit score, hurry timer and long feedback.

Final full managed Godot 4.7 run passed (`CHECKS_OK`); both mobile and desktop capture passes completed without engine errors. The managed command ran `python3 tests/run_checks.py`, then `godot --audio-driver Dummy --script capture.gd -- --touch-controls` and the same capture without the touch flag. Temporary source/import copies were removed after verification.

`tests/input_test.gd` uses real simulated input events to check touch/controller/mouse-preview behavior, rotation cancellation, fullscreen clearance, outlines, counter bounds, audio access, full-screen landscape fitting and stable yard size across pause. Added short-screen checks cover wrapped feedback disappearing before results and reachable Retry. Existing HUD tests cover mouse activation and focus behavior.

The unrelated Storm force regression fixture was repaired separately: its old heavy-body placement overlapped a tool stand, and the head-direction assertion mixed tornado force with cable tension. The repaired test checks both directions in a clear area, retains the heavy-scrap assertion, and rejects a temporary mass-gate removal. Production Storm behavior is unchanged.

### Unverified

This pass uses native touch emulation and desktop GPU rendering. No new Web export/deployment, physical-phone/notch-safe-area check, physical controller check or browser fullscreen test is claimed.
