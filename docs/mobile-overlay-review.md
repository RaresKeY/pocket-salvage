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
