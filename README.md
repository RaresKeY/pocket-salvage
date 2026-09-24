# Random Game

A small Godot 4.7 project for a collaboration experiment, organized around Jam Sync's conventions. The starting point is an empty main scene; the game concept and mechanics are still open.

## Start here

- Open `project.godot` with Godot 4.7.
- Read [the specs map](specs/_readme.md) for implemented reality and [the design map](design/_readme.md) for evolving intent.
- Read [the collaboration guide](docs/collaboration.md), and adapt [the instruction example](examples_agents/random-game.md) into your own ignored `AGENTS.md` or `CLAUDE.md` when useful.
- Use a short-lived `feature/<topic>` or `fix/<topic>` branch for one focused change, then open a pull request into `main`.
- Keep the relevant specs updated with implementation changes and include verification results in the pull request.

The repository is private on GitHub at [RaresKeY/random-game](https://github.com/RaresKeY/random-game). Collaborators need repository access before cloning. The [Jam Sync alignment map](docs/jam-sync-alignment.md) connects every source convention to its location and current status here.

## Structure

| Path | Purpose |
|---|---|
| [design/](design/_readme.md) | Evolving game, visual, and collaboration design; explicit user input stays distinct from AI inference. |
| [specs/](specs/_readme.md) | Current implementation, ownership, boundaries, and verification. |
| [TODO.md](TODO.md) | Small list of deferred work and open prerequisites. |
| [docs/](docs/README.md), [research/](research/README.md) | Contributor documentation and source-backed investigations. |
| [prototype/](prototype/README.md), [prompts/](prompts/README.md) | Visual candidates, input references, exact prompt records, and selection lineage. |
| [marketing/](marketing/README.md), [artifacts/](artifacts/README.md) | Intentional promotional deliverables and temporary working material. |
| [vendored/](vendored/_readme.md) | Third-party dependency provenance; empty of dependencies initially. |
| [tests/](tests/README.md), [tools/](tools/README.md) | Verification and one-shot creation utilities, respectively. |
| [examples_agents/](examples_agents/README.md), [examples/](examples/README.md) | Portable instruction examples and clearly labeled convention illustrations. |
| [scenes/](scenes/README.md), [scripts/](scripts/README.md), [assets/](assets/README.md), [data/](data/README.md), [shaders/](shaders/README.md), [native/](native/README.md) | Product source boundaries; only the empty main scene is implemented. |

Directory guides establish ownership without implying that gameplay, dependencies, art, or coordination tooling already exist. Journals and plans remain optional and have no required shared directory.

## Verify

On the shared workstation, run:

```sh
./tests/check
```

This uses the shared Godot Podman runner to import the project and briefly run its main scene without opening a desktop window. It looks for a sibling `godot-podman` checkout; set `GODOT_PODMAN_RUNNER` if the runner is installed elsewhere, including when using an external worktree lane.

With a local Godot 4.7 installation on another machine, the equivalent checks are:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 2
```

These are import and startup checks, not visual or hardware-renderer validation.
