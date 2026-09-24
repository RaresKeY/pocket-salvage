# Runtime Logic

Godot runtime scripts belong here, organized by the concepts or subsystems they implement. Keep creation utilities in `tools/` and checks in `tests/`. Update the relevant implementation specs when behavior changes.

`art/pixel_scaling.gd` owns bounded nearest-neighbor image enlargement, shared by the creation tool and lab. [rope/](rope/README.md) is the reusable crane-rope subsystem; `scene/yard_preview.gd` fits the main scene’s pixel canvas and HUD on resize. Game-specific round logic is not implemented yet.

[physics/](physics/README.md) supplies independent visual occlusion and caller-authored solid/sensor parts; it defines no concrete object or box dimensions.
