# Pocket Salvage

Control a magnetic crane, collect scrap, and sort it before the timer expires. Pocket Salvage is a small Godot 4.7 collaboration experiment, organized around Jam Sync's conventions. [Play in your browser](https://rareskey.github.io/pocket-salvage/) · [Download Windows/Linux/Web](https://github.com/RaresKeY/pocket-salvage/releases/latest).

Run the project to see the [scrapyard scene preview](specs/scene_preview.md), arranging the contributed crane, scrap and sorting-bin sprites. Choose **Play prototype** to try the [four-minute salvage round](labs/salvage/README.md): operate the crane, lift ten pieces of scrap and release them into matching bins. The yard composition remains separately inspectable. Open the [rope lab](labs/rope/README.md) to experiment with slack, reeling and terrain wrapping, or the [pixel-scaling lab](labs/pixel_scaling/README.md) to compare sampling. The [reusable rope component](scripts/rope/README.md) combines copied White Approach physics with Plug & Prosper's refined cable drawing.

The [object-physics components](scripts/physics/README.md) provide caller-authored solid shapes, separate sensors and visual occlusion masks. The [mask and collision fixture](labs/physics/README.md) demonstrates their independence. The playable lab supplies provisional concrete geometry; the reusable physics components remain independent.

## Start here

Run `./play.sh` on the shared workstation to import and play with desktop audio. It prepares a small local audio-enabled image on first use and forwards only the desktop PulseAudio/PipeWire-Pulse socket through the shared hardware GPU runner. Set `GODOT_PODMAN_RUNNER` outside the usual sibling checkout. Extra arguments pass to Godot, e.g. `./play.sh --fullscreen`.

- Open `project.godot` with Godot 4.7.
- Read [the specs map](specs/_readme.md) for implemented reality and [the design map](design/_readme.md) for evolving intent.
- Read [the collaboration guide](docs/collaboration.md). Use the [portable instruction example](examples_agents/random-game.md) for local, ignored `AGENTS.md` and `CLAUDE.md`: read specs and design first, update both with every change, and keep explicit human direction separate from AI inference.
- Commit directly to `main`; use an experimental branch only when separation helps. Rebase unpublished commits onto the latest remote before every push. No pull requests. Release tags are reserved for explicitly requested GitHub releases.
- Keep the relevant specs updated with implementation changes and record verification with the commits. Start with a shared design spike, then implement a small MVP.

The standalone prototype is **v0.1.3**, shown in the HUD. Main pushes run the game tests. Pushing a stable `vMAJOR.MINOR.PATCH` tag that matches `project.godot` tests and builds Windows, Linux and Web, compares two independent exports, publishes release ZIPs and checksums, and updates the playable Pages site. See [the build contract](specs/builds.md) for release commands and platform validation limits. Local builds still use `python3 tools/build/build_all.py --targets windows linux web --verify`; generated outputs are ignored and removed after verified publication.

**Push and conflict rules:** always fetch `origin` before pushing. If `origin/main` has advanced, rebase unpublished commits onto it, inspect the combined result and rerun relevant checks. If a push loses a race, fetch and rebase again; never force-push shared history. For simple compatible conflicts, AI should resolve them while keeping all contributors' work. If AI cannot preserve all work, or the intended direction splits, **stop and ask the user for direction** before resolving or pushing. Preserve both versions and local commits; do not silently choose a side.

The public repository is [RaresKeY/pocket-salvage](https://github.com/RaresKeY/pocket-salvage). Existing collaborators retain write access; see [migration notes](docs/collaboration.md#repository-migration) before pulling. The [Jam Sync alignment map](docs/jam-sync-alignment.md) connects every source convention to its location and current status here.

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
| [labs/](labs/README.md) | Standalone rope, mask/collision, pixel-scaling and sprite playground showcases. |
| [examples_agents/](examples_agents/README.md), [examples/](examples/README.md) | Portable instruction examples and clearly labeled convention illustrations. |
| [scenes/](scenes/README.md), [scripts/](scripts/README.md), [assets/](assets/README.md), [data/](data/README.md), [shaders/](shaders/README.md), [native/](native/README.md) | Source boundaries; reusable rope and pixel-scaling modules, diagnostic media, and the arranged scrapyard scene. |

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
