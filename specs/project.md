# Project Contract

Reviewed: 2026-09-24. Implementation revision: `be7e1eb`.

## Status and scope

Random Game is an initial Godot 4.7 scaffold for a collaboration experiment. `project.godot` selects `scenes/main.tscn`, which currently contains only an empty root node. There is no gameplay yet. The genre, mechanics, art direction, and delivery platforms remain undecided.

## Source ownership

- `project.godot` owns engine features, project identity, startup scene, and renderer settings.
- `scenes/main.tscn` owns the initial scene tree.
- `tests/check` owns the workstation import and startup checks through the external shared Godot Podman runner. It resolves the runner from a sibling checkout or `GODOT_PODMAN_RUNNER`.
- [Repository structure](repository.md) describes project memory, collaboration, file handling, and the source layout.

## Collaboration contract

The private GitHub repository uses direct commits to `main`, rebasing unpublished work onto the latest remote before pushing. Experimental branches are optional; pull requests and release tags are not part of the current workflow. The [collaboration guide](../docs/collaboration.md) owns conflict, recovery, and build-identity rules. Optional future coordination automation lives in [design](../design/collaboration.md).

`project.godot` uses the private-development base `0.0.0`. Local reproducible builds are intended to carry `0.0.0+<short-sha>` from their clean, rebased source commit; build-time stamping is not implemented. Explicit release versions are assigned in-game only for public builds. No project license has been selected.

## Verification

`./tests/check` runs an editor import and a two-frame headless startup through the shared runner in one managed container. Both commands must exit successfully, and their output must be checked for engine errors. These checks establish that the starter imports and starts; they do not establish gameplay correctness, visual quality, or hardware rendering. The equivalent local Godot commands are in `README.md`.

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.
