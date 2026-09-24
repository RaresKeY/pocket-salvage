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

The private GitHub repository uses `main` as the integration branch and focused feature or fix branches for contributions. The [collaboration guide](../docs/collaboration.md) describes the manual workflow; the [coordination design](../design/collaboration.md) distinguishes proposed lock automation from current capabilities. The scaffold version is not a published game release. No project license has been selected.

## Verification

`./tests/check` runs an editor import and a two-frame headless startup through the shared runner in one managed container. Both commands must exit successfully, and their output must be checked for engine errors. These checks establish that the starter imports and starts; they do not establish gameplay correctness, visual quality, or hardware rendering. The equivalent local Godot commands are in `README.md`.

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.
