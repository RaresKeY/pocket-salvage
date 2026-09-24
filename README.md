# Pocket Salvage

Control a magnetic crane, collect scrap, and sort it before the timer expires. Pocket Salvage is a small Godot 4.7 collaboration experiment, organized around Jam Sync's conventions. The repository and upstream remain **`random-game`**.

The game loop is selected; implementation currently consists of technical labs. Open the [rope lab](labs/rope/README.md) to experiment with slack, reeling and terrain wrapping. The [pixel-scaling lab](labs/pixel_scaling/README.md) remains the default startup scene. The [reusable rope component](scripts/rope/README.md) combines copied White Approach physics with Plug & Prosper's refined cable drawing.

## Start here

- Open `project.godot` with Godot 4.7.
- Read [the specs map](specs/_readme.md) for implemented reality and [the design map](design/_readme.md) for evolving intent.
- Read [the collaboration guide](docs/collaboration.md), and adapt [the instruction example](examples_agents/random-game.md) into your own ignored `AGENTS.md` or `CLAUDE.md` when useful.
- Commit directly to `main`; use an experimental branch only when separation helps. Rebase unpublished commits onto the latest remote before every push. No pull requests or release tags.
- Keep the relevant specs updated with implementation changes and record verification with the commits. Start with a shared design spike, then implement a small MVP.

Private development has no release-version increments. Reproducible local builds should identify their clean source commit as `0.0.0+<short-sha>`; assign an explicit in-game release version only when building a public release. The current project version is the neutral `0.0.0` base; build-time SHA stamping is not implemented yet.

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
| [vendored/](vendored/_readme.md) | Dependency and copied-source provenance, including the original rope implementations. |
| [tests/](tests/README.md), [tools/](tools/README.md) | Verification and one-shot creation utilities, respectively. |
| [labs/](labs/README.md) | Runnable rope and pixel-scaling showcases; pixel scaling is the current entry point. |
| [examples_agents/](examples_agents/README.md), [examples/](examples/README.md) | Portable instruction examples and clearly labeled convention illustrations. |
| [scenes/](scenes/README.md), [scripts/](scripts/README.md), [assets/](assets/README.md), [data/](data/README.md), [shaders/](shaders/README.md), [native/](native/README.md) | Source boundaries; reusable rope and pixel-scaling modules, diagnostic media, and a reserved game scene. |

Directory guides establish ownership without implying that gameplay, dependencies, art, or coordination tooling already exist. Journals and plans remain optional and have no required shared directory.

## Verify

On the shared workstation, run:

```sh
./tests/check
```

This uses the shared Godot Podman runner for project import, exact-pixel and CLI tests, lab interaction checks, and headless startup. It looks for a sibling `godot-podman` checkout; set `GODOT_PODMAN_RUNNER` if the runner is installed elsewhere, including when using an external worktree lane. [The lab guide](labs/pixel_scaling/README.md) covers superscaling and background GPU captures.

With local Godot 4.7 and Python 3 on another machine, subject to its execution rules, run the same suite:

```sh
python3 tests/run_checks.py
```

These include deterministic subsystem checks, but do not establish visual or hardware-renderer quality. `./labs/capture rope` performs the separate background GPU showcase check.
