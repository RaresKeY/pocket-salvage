# Controller and mobile Web review

Reviewed: 2026-09-25. Implementation: `6488a44` (v0.1.4).

## Verdict

Pass for automated behavior and inspected native/Web presentation. Physical-device compatibility remains unverified.

## Scope

Standard gamepad commands, automatic mobile Web touch controls, phone layouts, and the main checkout rename. Preserve crane physics, sorting/scoring, art, keyboard controls and the dark/mint HUD theme.

## Findings and changes

- A phone-sized baseline clipped the modal and crushed header labels. The header now wraps; the modal stays below it; portrait footer content stacks.
- Landscape touch controls need yard space without overlap. A bottom-right panel reserves a side column below 540 logical pixels of height. Targets stay at least 44×44 CSS pixels, including DPR 3.
- Shared input routing preserves proportional stick movement and independent reel/trolley axes. Single gamepad presses cannot also activate focused GUI buttons. Touch ownership supports simultaneous movement/reel/grip, drag-off release and cancellation.
- Pause, focus loss, rotation and disconnect clear held input; physical movement requires neutral before resuming. The existing navigation test caught a freed-viewport access after F2 scene changes; handling the event before emitting fixes it.
- Actual Web export revealed missing Unicode arrow glyphs. Canvas-drawn arrows remove the font dependency; regression assertions and rebuilt-browser screenshots cover the fix.
- The checkout is `~/workspace/pocket-salvage`. Nine sibling worktrees retain their existing names and branches; their Git links were repaired. Ignored local agent files moved with the checkout.

## Verification

The complete managed Godot suite passed, including the new input regression test, existing keyboard/mouse navigation and ten-piece physics playthrough. Eight release-contract tests passed. Two clean local Web exports matched byte for byte.

Background Gamescope/native GPU captures covered ready/running/paused/finished at 1920×1080, 1280×720, 960×540 and 854×480; touch additionally covered 844×390, 390×844 and 320×568. The native log identified NVIDIA RTX 2080 Ti. Small portrait and landscape states were visually inspected. Native screenshots preceded the final font-independent arrow fix; rebuilt Web screenshots verify that fix.

Firefox loaded the actual exported package at DPR 3 with Android and iPad desktop-site identities. Real browser touch events started play, moved/reeled/gripped together, paused/resumed and rotated with held input. Screenshots showed the steel pickup and clear directional icons. A synthetic standard Gamepad API device exercised start, analog movement, grip/swap, audio toggles, pause/resume/restart and disconnect. No game-console errors occurred. Firefox exposes a privacy-masked NVIDIA renderer, not exact adapter identification. Desktop presentation does not automatically show mobile controls.

The published HTTPS Pages game was checked again with mobile touch and simulated gamepad input: the expected states and icons were visible, with no game-console errors. The v0.1.4 tag workflow passed in 2m41s, including two-snapshot Windows/Linux/Web exports and remote byte verification. The downloaded Linux release started cleanly on the same hardware renderer.

Local evidence is retained under ignored `.local/input/` (checks/build logs, native captures and browser reports). Release and live-site validation is recorded in [build specs](../specs/builds.md).

## Unverified

No physical phone or gamepad was attached for this review; browser identity and gamepad data were simulated. Safari/Chrome mobile behavior and vendor-specific controller mappings require real-device checks. Windows execution and subjective speaker listening remain unverified. `play.sh` does not forward host gamepad devices into its container; use the Web game or native download for physical gamepad play.
