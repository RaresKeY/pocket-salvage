# Rope module

Reusable Godot 4.7 2D component, maintained in this repository (not a Git submodule or an external checkout). No game singleton or asset dependency.

```gdscript
const Rope = preload("res://scripts/rope/rope_2d.gd")
var rope := Rope.new()
add_child(rope)
rope.configure(closed_static_polygons) # same world space as collision geometry
rope.reset(anchor_position, load_position, paid_out_length)
# Each physics tick: constrain/move your load with collision, then:
rope.step(anchor_position, load_position, paid_out_length, delta)
```

`constrain_tip(anchor, position, velocity, length)` returns the proposed constrained position and velocity plus `blocked` when fixed spans leave insufficient reach. The caller must apply displacement through its body's collision handling; the rope never teleports a body. Keep endpoint motion and `step` at 60 Hz. `collision_mask` and `exclude` govern swept particle contacts. `configure` accepts static closed non-overlapping solid polygons, with endpoints outside them. Reconfigure/reset after replacing geometry.

Copy `scripts/rope/` as a unit to reuse; preserve the [source provenance](../../vendored/rope_sources/README.md). The solver handles slack, tension-only constraints, persistent static corner guides and particle sweeps. Rendering retains all pinned contacts. No self-collision, moving-polygon wrapping, elastic material model, load mass feedback, or 3D solver is claimed.

See the [lab](../../labs/rope/README.md) and [contract](../../specs/rope.md).
