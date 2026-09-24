# Object subsystem design

## User design

After the rope milestone is committed and pushed, prepare physics support for objects and the magnet. Clarification: provide a collision-box capability and a mask to hide parts behind, keep other physics boxes separate, and implement the submodule that can use them rather than the concrete boxes/objects now. The [source record](../prompts/source/pocket-salvage.md) preserves that correction.

## AI-inferred design

Use orthogonal Godot components: caller-authored Shape2D solids, independently authored Area2D sensors, and a visual alpha occluder. Delay object layouts, exact box dimensions, magnet mechanics and any automatic bitmap-to-physics conversion. A visual mask can move without changing physical shape, and collision channels can change without changing art.

The fixture uses synthetic geometry and a contributed bin alpha mask only to prove composability. It is not a selected bin implementation or a prototype of magnet handling. Current API and limitations live in [the physics spec](../specs/physics.md).
