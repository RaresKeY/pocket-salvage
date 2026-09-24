# Random Game

A small Godot 4.7 project for a collaboration experiment. The starting point is an empty main scene; the game concept and mechanics are still open.

## Start here

- Open `project.godot` with Godot 4.7.
- Read [the specs map](specs/_readme.md) for the current project contract.
- Use a short-lived `feature/<topic>` or `fix/<topic>` branch for one focused change, then open a pull request into `main`.
- Keep the relevant specs updated with implementation changes and include verification results in the pull request.

The repository is private on GitHub at [RaresKeY/random-game](https://github.com/RaresKeY/random-game). Collaborators need repository access before cloning.

## Verify

On the shared workstation, run:

```sh
./tools/check
```

This uses the shared Godot Podman runner to import the project and briefly run its main scene without opening a desktop window. Set `GODOT_PODMAN_RUNNER` if the runner is installed elsewhere. The default runner location is `~/workspace/godot-podman/bin/godot-podman`.

With a local Godot 4.7 installation on another machine, the equivalent checks are:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 2
```

These are import and startup checks, not visual or hardware-renderer validation.
