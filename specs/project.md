# Project Contract

## Status and scope

Random Game is an initial Godot 4.7 scaffold for a collaboration experiment. `project.godot` selects `scenes/main.tscn`, which currently contains only an empty root node. There is no gameplay yet. The genre, mechanics, art direction, and delivery platforms remain undecided.

## Source ownership

- `project.godot` owns engine features, project identity, startup scene, and renderer settings.
- `scenes/main.tscn` owns the initial scene tree.
- `tools/check` owns the workstation import and startup checks through the external shared Godot Podman runner.
- `README.md` and `AGENTS.md` describe contributor entry points and collaboration rules.
- `.gitignore` excludes generated engine data, reproducible output, and local-only state; `specs/` remains tracked.

## Collaboration contract

The project uses a private GitHub repository, `RaresKeY/random-game`, with `origin` as its remote. `main` is the integration branch. Contributors work on short-lived feature or fix branches and open pull requests into `main`; no permanent development or release branches are required at this stage. Concurrent contributors use separate worktrees or clones.

These are documented conventions, not enforced branch-protection settings. Collaborator invitations and repository access rules are not part of the initial scaffold.

Behavior changes include the corresponding spec updates and relevant verification evidence. Git tags should identify actual releases when a release process is introduced. The scaffold version is not a published game release. No project license has been selected.

## Verification

`./tools/check` runs an editor import and a two-frame headless startup through the shared runner in one managed container. Both commands must exit successfully, and their output must be checked for engine errors. These checks establish that the starter imports and starts; they do not establish gameplay correctness, visual quality, or hardware rendering. The equivalent local Godot commands are in `README.md`.

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.
