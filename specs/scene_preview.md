# Scrapyard Scene Preview

Reviewed: 2026-09-24 against the scene-preview changes based on `d163a53`.

## Composition and ownership

`scenes/main.tscn` is the project startup scene. It arranges Dale Mooney’s original `assets/bitwright/` PNGs as a static side-on scrapyard. Named editable Node2D groups separate the tiled environment, gantry, conveyor and incoming scrap, suspended magnet/cog, three sorting bins, and foreground scrap. All thirteen scrap types appear. The supplied dust and spark art use representative still frames; conveyor and magnet use their first frames. Collision/catch/pull masks are not rendered or connected to physics.

`Presentation/HUD` is a CanvasLayer with native-resolution Controls and a shared scene Theme. The contributed coin and timer icons accompany static `000` and `--:--` placeholders. The footer credits Dale Mooney and labels the scene as a preview. There are no interactive controls, timer progression, scoring, crane movement, sorting, or rope integration.

## Presentation contract

`Stage/Viewport` renders a 384×216 art canvas. `scripts/scene/yard_preview.gd` centers it at the largest integer scale that fits, floors its screen origin, and fits the unscaled HUD to its displayed rectangle. The script also runs in the editor. All sprites preserve their native pixel dimensions; the taller towers reuse an unscaled upper section. No enlarged PNG derivatives are created. Only intentionally tiled sprites override texture repeat.

The default window is 1280×720, with a minimum of 768×480 so the art has at least 2× scale and the native-size header fits. At 1920×1080 the art is 5×; at 1280×720 it is 3×; at 960×540, 854×480 and 768×480 it is 2×. Unused space is a dark border. This is a provisional preview canvas, not the final gameplay resolution. Root stretch remains disabled so the standalone labs retain their own layouts.

## Verification and boundaries

`./tests/check` imports the project, runs the existing subsystem/lab checks, and starts the default main scene. The pixel lab test and capture launcher select their own scene explicitly.

Inspect the main scene at 1920×1080, 1280×720, 960×540, 854×480 and the minimum 768×480 using the shared hardware-enabled Godot runner inside Gamescope’s headless backend. Check complete art/HUD visibility, crisp blocks, and the actual GPU renderer. A desktop window is opened only on user request. Local captures and review notes belong under ignored `.local/`.

A static composition check establishes no collision, gameplay, controller, animation, export, or performance behavior. Final sorting rules and integration of the supplied masks remain deferred with the timed round.
