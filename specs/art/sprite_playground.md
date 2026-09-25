# Enlarged sprite playground

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`.

User intent: preserve pixel art through integer enlargement, store enlarged copies in a new folder, then render those textures at adjustable smaller sizes with filtering and demonstrate a grabbable physics object. The user selected an 8× enlargement.

`assets/bitwright_8x/` contains 123 PNG derivatives of `assets/bitwright/`, including 27 masks. The 42 added on 2026-09-25 (night scenery, critters, smoke, the claw head and the tool stand, drawn with Bitwright's `scrapyard` set) arrive through `tools/pixel_art/import_bitwright.py`, which copies render-game output under game names and runs the same superscale CLI. The existing superscale CLI creates exact 8×8 RGBA blocks and adjacent provenance records. Originals are retained. These requested runtime source assets are durable; they are not build/export artifacts.

`labs/sprite_playground/lab.tscn` displays one tile per non-mask sprite (47; animations show their first frame) in a uniformly fitted gallery and one dynamic washing machine. Its 192×224 texture remains enlarged in memory; sprite scale is display factor / 8. Linear sampling is the default, with a nearest toggle. No mipmaps are generated. Screen resampling at fractional sizes/angles does not promise pixel-perfect blocks.

`grabbable.gd` owns a RigidBody2D, off-center damped spring mouse grab, bounded force, release velocity, Q/E torque while grabbed, and focus-loss release. The body stays at unit scale. Size changes from 1× to 4× original dimensions update sprite scale and a caller-authored 22×26 rectangle scaled by the same factor; resizing resets the object to avoid resizing into a wall. This lab approximation is independent of alpha masks. Static arena boundaries contain the body; reset clears motion. No final scrap taxonomy, magnet mechanics or gameplay loop is introduced.

The standalone pixel-scaling scene links to this scene through its Sprite playground button; the scrapyard preview is the project startup. Tests verify exact enlarged data and hashes for all 123 files, gallery count, gravity/floor containment, body versus sprite scale, collision dimensions, filter toggling, viewport mouse picking/release and reset. `labs/capture sprite_playground` provides separate background hardware-renderer evidence. No performance or exported-game acceptance is claimed.

Validation: `./tests/check` passed with Godot 4.7. Background Gamescope captures at 1280×900 and 854×480 used NVIDIA GeForce RTX 2080 Ti; the final header placement was rechecked at 1280×900. The overview fits the smaller viewport, but gallery filename labels are only useful at larger window sizes.
