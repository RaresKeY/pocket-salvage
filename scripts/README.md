# Runtime Logic

Godot runtime scripts belong here, organized by the concepts or subsystems they implement. Keep creation utilities in `tools/` and checks in `tests/`. Update the relevant implementation specs when behavior changes.

`art/pixel_scaling.gd` owns bounded nearest-neighbor image enlargement, shared by the creation tool and lab. [rope/](rope/README.md) is the reusable crane-rope subsystem; `scene/yard_preview.gd` owns the main scene’s smooth inspection camera and native HUD. `round/` holds the timed sorting round and bins, and `fx/burst_2d.gd` plays the contributed six-frame sparks and dust as one-shot effects.

[physics/](physics/README.md) supplies independent visual occlusion and caller-authored solid/sensor parts; it defines no concrete object or box dimensions.
