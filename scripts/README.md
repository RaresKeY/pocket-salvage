# Runtime Logic

Godot runtime scripts belong here, organized by the concepts or subsystems they implement. Keep creation utilities in `tools/` and checks in `tests/`. Update the relevant implementation specs when behavior changes.

`art/pixel_scaling.gd` owns bounded nearest-neighbor image enlargement, shared by the creation tool and lab. [rope/](rope/README.md) is the reusable crane-rope subsystem; game-specific round logic is not implemented yet.
