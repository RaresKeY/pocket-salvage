# Project Contract

Reviewed: 2026-09-24 integrating the scene preview with the physics components and 8× sprite playground.

## Status and scope

Pocket Salvage is the official game name; its private GitHub repository remains `random-game`. The selected loop is a magnetic crane collecting and sorting scrap before time expires. Godot 4.7 opens the [scrapyard scene preview](scene_preview.md) in `scenes/main.tscn`, arranging Dale Mooney’s contributed sprites. The pixel-scaling and rope labs remain separate runnable scenes. The preview is static: crane controls, collision/mask integration, sorting, scoring and the timed round remain unimplemented. Final art direction and delivery platforms remain open.

## Source ownership

- `project.godot` owns engine features, project identity, startup scene, and renderer settings.
- `scenes/main.tscn` owns the editable yard composition; `scripts/scene/yard_preview.gd` owns its smooth inspection camera and native HUD.
- `labs/pixel_scaling/` owns the standalone scaling lab; [the art module](art/_readme.md) owns its scaling/filtering contract and related creation tool.
- `scripts/rope/` and `labs/rope/` own the [rope subsystem and showcase](rope.md); `vendored/rope_sources/` preserves original copied source.
- `scripts/physics/`, `shaders/occlusion_mask.gdshader` and `labs/physics/` own [separate visual mask, solid and sensor capabilities](physics.md). Concrete game objects remain deferred.
- `tests/check` runs `tests/run_checks.py` through the external shared Godot Podman runner. It resolves the runner from a sibling checkout or `GODOT_PODMAN_RUNNER`.
- [Repository structure](repository.md) describes project memory, collaboration, file handling, and the source layout.

## Collaboration contract

The private GitHub repository uses direct commits to `main`, rebasing unpublished work onto the latest remote before pushing. Experimental branches are optional; pull requests and release tags are not part of the current workflow. The [collaboration guide](../docs/collaboration.md) owns conflict, recovery, and build-identity rules. Optional future coordination automation lives in [design](../design/collaboration.md).

`project.godot` uses the private-development base `0.0.0`. Local reproducible builds are intended to carry `0.0.0+<short-sha>` from their clean, rebased source commit; build-time stamping is not implemented. Explicit release versions are assigned in-game only for public builds. No project license has been selected.

## Verification

`./tests/check` runs editor import, exact-pixel and CLI tests, lab control checks, and a two-frame headless startup in one managed container. Each child process has a timeout; script errors and missing success markers fail the suite. These checks do not establish gameplay correctness, visual quality, or hardware rendering. The separate background GPU capture flow is described in [the lab spec](art/pixel_scaling.md).

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.
