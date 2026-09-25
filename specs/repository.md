# Repository Structure

Reviewed: 2026-09-25. Game implementation revision: `07f1974` (v0.1.5); hosting configuration revision: `8cb7b69`; README facts reviewed 2026-09-25.

## Current contract

The repository implements Jam Sync's organizational conventions through tracked maps and directory guides. [The alignment map](../docs/jam-sync-alignment.md) accounts for each source idea, including the optional and design-only parts. These directories are source-ownership boundaries; their presence does not mean a subsystem has been implemented.

- `design/` records evolving intent, separating explicit user direction from AI-inferred proposals. `specs/` describes current reality and records the implementation revision reviewed. `TODO.md` holds deferred work. Plans and journals are optional and separate from all three.
- `docs/` holds contributor guidance; `research/` holds dated, source-backed investigations. `prototype/` holds visual targets and references, `prompts/` preserves exact directives and generation lineage, `marketing/` holds intentional promotional deliverables, and `artifacts/` holds working material according to its reproducibility.
- `vendored/` maps dependency ownership and provenance, including copied user-owned rope source snapshots. The bundled Tiny5 font is recorded in `vendored/tiny5.md`; `THIRD_PARTY_NOTICES.md` and its complete OFL file preserve the required attribution.
- `tests/` owns verification, `tools/` owns creation utilities (`superscale`, `pixel_art/` including `import_bitwright.py`, `audio/` sound and music generators, `build/`), and `labs/` owns runnable technical comparisons. The pixel-scaling tool and lab share `scripts/art/` and diagnostic media under `assets/pixel_lab/`. The reusable rope lives under `scripts/rope/` with its own lab and focused spec. Other product source areas remain ready for the later game.
- `examples_agents/` contains portable instructions to adapt locally. `examples/` contains illustrations that are not accepted game design or actual generation records.

`scripts/physics/` and its focused spec own caller-authored solid/sensor parts and visual masks, with `shaders/occlusion_mask.gdshader` and a diagnostic lab. The component supplies no concrete game object or chosen collision box dimensions.

## Local and shared state

Root `AGENTS.md` and `CLAUDE.md` are ignored and untracked, preserved locally when removed from the index. Portable rules remain in `examples_agents/` and `docs/collaboration.md`: read and update specs/design with changes, quote explicit human direction in `prompts/source/`, and distinguish AI inference. This follows RaresKeY’s latest 2026-09-25 directive. Older tracked revisions remain in public Git history; collaborator migration notes explain backing up local copies before pulling the deletion.

`.gitignore` excludes engine caches, build/export output, local journals and scratch state, secrets files, and the reproducible `artifacts/tmp/` and `artifacts/generated/` buckets. It does not blanket-ignore `artifacts/`, visual candidates, or shared source. Preserve non-reproducible evidence and authored deliverables according to purpose, and review them before tracking. Reproducible release outputs are ephemeral under the owning release workflow.

`.gitattributes` normalizes text, pins Godot source and script formats to LF, and marks binary media as binary. `artifacts/.gdignore` prevents Godot from importing working outputs and captures. Tracked references use project-relative paths; machine installation details belong in environment variables or ignored local instructions.

## Collaboration and verification

The public GitHub `origin`, `RaresKeY/pocket-salvage`, is the collaboration remote, renamed from `random-game`. Contributors commit directly to `main`, rebase unpublished commits before every push, preserve work during conflicts, and recover with bisect and corrective commits. Experimental branches and external worktrees are optional. Pull requests are not used. Release tags are reserved for explicitly requested GitHub releases. Atomic ownership locks remain an optional future design; no lock manager or automatic recovery is implemented. Existing collaborator grants are retained. `.github/workflows/delivery.yml` tests main pushes and publishes stable tag releases; generated Web output lives on the separate `gh-pages` deployment branch, never in main. See [builds](builds.md).

README, collaboration guidance and the portable instruction example explicitly require fetching before push and rebasing if origin has advanced, including a push race. AI preserves all work through simple compatible conflicts. If that is impossible or the direction bifurcates, stop and ask the user before resolving or pushing; preserve both versions. Local agent instructions can import or copy the portable example.

Check Markdown links, the tracked/ignored boundary, Git attributes, and `git diff --check` after structure changes. Run `./tests/check` when engine sources or the check entry point change. Keep current behavior in specs and unfinished implementation work in `TODO.md`.

## Public entry point

The root README leads with browser play and desktop downloads, a selected live-game screenshot, controls, and short development links. Detailed contributor and build rules remain in their owning docs/specs. `marketing/.gdignore` prevents the README capture from becoming a game resource.

The main workstation checkout is now named `pocket-salvage`. Git links for its nine existing sibling worktrees were repaired after the move; their paths and branches remain intact. Launchers resolve the project from their own location, so they follow the rename without hard-coded path changes. Local instruction files moved with the checkout and remain ignored.

The public About website is Firebase Hosting (`https://pocket-salvage.web.app/`), a manually deployed v0.1.6 snapshot. README retains GitHub Pages as the destination updated by tagged releases and labels that difference. Firebase configuration is tracked; credentials, deployment caches/logs and downloaded release payloads are not.

The README summarizes the current release’s weather and retained audio/performance changes, executable names, browser audio activation, Web ZIP serving requirements and Linux launcher prerequisites. It links the test guide and measured performance review; hosted version metadata and latest-release identity were checked during the refresh.
