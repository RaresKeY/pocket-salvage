# Project Contract

Reviewed: 2026-09-24. Implementation revision: `2cff8e5`.

## Status and scope

Random Game is a Godot 4.7 collaboration experiment. `project.godot` currently opens `labs/pixel_scaling/lab.tscn`, an interactive art-sampling comparison. `scenes/main.tscn` remains an empty future-game scene. There is no gameplay yet. The genre, mechanics, game art direction, and delivery platforms remain undecided.

## Source ownership

- `project.godot` owns engine features, project identity, startup scene, and renderer settings.
- `labs/pixel_scaling/` owns the temporary entry point; [the art module](art/_readme.md) owns its scaling/filtering contract and related creation tool.
- `tests/check` runs `tests/run_checks.py` through the external shared Godot Podman runner. It resolves the runner from a sibling checkout or `GODOT_PODMAN_RUNNER`.
- [Repository structure](repository.md) describes project memory, collaboration, file handling, and the source layout.

## Collaboration contract

The private GitHub repository uses direct commits to `main`, rebasing unpublished work onto the latest remote before pushing. Experimental branches are optional; pull requests and release tags are not part of the current workflow. The [collaboration guide](../docs/collaboration.md) owns conflict, recovery, and build-identity rules. Optional future coordination automation lives in [design](../design/collaboration.md).

`project.godot` uses the private-development base `0.0.0`. Local reproducible builds are intended to carry `0.0.0+<short-sha>` from their clean, rebased source commit; build-time stamping is not implemented. Explicit release versions are assigned in-game only for public builds. No project license has been selected.

## Verification

`./tests/check` runs editor import, exact-pixel and CLI tests, lab control checks, and a two-frame headless startup in one managed container. Each child process has a timeout; script errors and missing success markers fail the suite. These checks do not establish gameplay correctness, visual quality, or hardware rendering. The separate background GPU capture flow is described in [the lab spec](art/pixel_scaling.md).

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.
