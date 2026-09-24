# Scrapyard Scene Preview

Reviewed: 2026-09-24 against the camera/8× texture extension of `b296d7f`.

## Composition and ownership

`scenes/main.tscn` is the project startup scene. It arranges 8× nearest-neighbor derivatives of Dale Mooney’s `assets/bitwright/` PNGs from `assets/bitwright_8x/` as a static side-on scrapyard. Named editable Node2D groups separate the tiled environment, gantry, conveyor and incoming scrap, suspended magnet/cog, three sorting bins, and foreground scrap. All thirteen scrap types appear. The supplied dust and spark art use representative still frames; conveyor and magnet use their first frames. Collision/catch/pull masks are not rendered or connected to physics.

`Presentation/HUD` is a CanvasLayer with native-resolution Controls and a shared scene Theme. The contributed coin and timer icons accompany static `000` and `--:--` placeholders. The footer credits Dale Mooney and shows camera controls. Mouse wheel zooms smoothly toward the pointer, left or middle drag pans, and F resets the view. The preview itself has no timer progression, scoring, crane movement, sorting, or rope integration. Its Play prototype button launches [the combined playable lab](salvage_prototype.md), whose F2 shortcut returns here.

## Presentation contract

`Stage/Viewport` renders at window resolution. The composition retains its 384×216 world-unit coordinates. Each Sprite2D uses an 8× texture with local scale 0.125, while region rectangles multiply by eight to preserve cropping and tile repetition. HUD textures also use the enlarged copies within their existing fixed display bounds. Originals remain untouched; all 75 derivatives, including masks, retain adjacent hash/provenance records. Only deliberately tiled sprites enable repeat.

Linear filtering is scene-local and happens at runtime on the enlarged textures; the stored PNGs contain exact replicated blocks. No mipmaps are enabled. Smooth zoom and fractional placement intentionally allow resampling and do not promise pixel-perfect blocks at every zoom.

`scripts/scene/yard_preview.gd` owns a canvas transform: absolute zoom is clamped to 0.5–32 screen pixels per world unit; wheel steps multiply the target by 1.18 and exponential interpolation approaches it with rate 14/s. The world point under the latest wheel event stays anchored during interpolation. Dragging cancels pending zoom, applies screen delta divided by zoom, and stops on matching button release or focus loss. Panning is unrestricted; F restores the centered largest fitting integer zoom. Resizing preserves the camera center and uses the new window resolution. In-editor rendering fits the composition without intercepting editor input.

The native HUD stays fixed independently of camera movement, fitted to the original composition rectangle. The window defaults to 1280×720 and has a 768×480 minimum. Root stretch remains disabled. This is a review camera over the provisional composition, not a final gameplay camera.

## Verification and boundaries

`./tests/check` imports the project, runs the existing subsystem/lab checks, and starts the default main scene. `tests/yard_camera_test.gd` checks enlarged texture bindings and regions, native viewport sizing, interpolated cursor anchoring, zoom bounds, left/middle drag, release/focus cancellation, reset and resize. The pixel lab test and capture launcher select their own scene explicitly.

Inspect the main scene at 1920×1080, 1280×720, 960×540, 854×480 and the minimum 768×480 using the shared hardware-enabled Godot runner inside Gamescope’s headless backend. Check complete art/HUD visibility at reset, filtered zoom/pan views, and the actual GPU renderer. A desktop window is opened only on user request. Local captures and review notes belong under ignored `.local/`.

A static composition check establishes no collision, gameplay, controller, animation, export, or performance behavior. Final sorting rules and integration of the supplied masks remain open; the separate playable lab exercises provisional round rules.

2026-09-24 validation: full `./tests/check` passed, including camera input tests. Background Gamescope captures at 1280×720 and 854×480 plus a zoomed/panned 1280×720 view confirmed NVIDIA GeForce RTX 2080 Ti rendering. All 75 source/output provenance hashes match.
