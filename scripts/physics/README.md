# Mask and collision components

Reusable Godot 4.7 components for Pocket Salvage. These do **not** create a magnet, scrap, bin, fixed collision box, magnetic force or timed game. The caller supplies object scenes and geometry later.

- `visual_mask_2d.gd`: attach to a `Node2D`, assign `target: Sprite2D` and `mask_texture`. Position/rotate/scale the node to place a centered world-space mask. Opaque mask alpha hides pixels on the target; transparent mask alpha and pixels outside its rectangle leave the target unchanged. RGB does not matter. A missing texture or disabled/zero-scale mask leaves the target visible. Use an alpha PNG, nearest filtering and no mipmaps. This is visual occlusion only; it never reads or writes collision geometry.
- `collision_parts_2d.gd`: `add_solid(body, shape, local_transform)` adds a private copy of a caller-authored `Shape2D` to any `PhysicsBody2D`. `add_sensor(parent, shape, layer, mask, local_transform)` adds a separate `Area2D` with its own copied shape and filter. A box is simply a caller-supplied `RectangleShape2D`; other `Shape2D` types work the same way. Null inputs return null. `set_solid_enabled` and `set_sensor_enabled` defer their writes for safe use from contact/overlap signals.

```gdscript
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
var solid = Parts.add_solid(body, authored_solid_shape)
var sensor = Parts.add_sensor(body, authored_sensor_shape, sensor_layer, sensor_mask)
# Independently place a VisualMask2D and assign its target + alpha texture.
```

Shape transforms are relative to their body/parent. Author dimensions at the intended physics scale; avoid non-uniform scaling of physics bodies. Collision layers/masks belong to the caller, not to artwork. Visual clipping never changes hitboxes, sensor overlap, mass or movement. The helpers do not convert PNG silhouettes to physics polygons.

The visual component uses `shaders/occlusion_mask.gdshader`; copy that file with `scripts/physics/` when reusing. One mask may bind one sprite in the **same canvas/viewport**. The component temporarily owns the sprite's material and restores it when detached. It does not compose an existing custom shader, stack masks, mask entire subtrees, infer front/back order, or support cross-CanvasLayer coordinate spaces. Callers choose which sprites are behind the occluder; other sprites retain ordinary drawing order. Do not bind two mask components to one target.

[The lab](../../labs/physics/README.md) exercises these components with disposable diagnostic shapes. [The spec](../../specs/physics.md) records tests and boundaries.
