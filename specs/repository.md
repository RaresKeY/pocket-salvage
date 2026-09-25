# Repository Structure

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`. Reference conventions: Jam Sync `d2c801a`, with the user's direct-main collaboration rules.

## Current contract

The repository implements Jam Sync's organizational conventions through tracked maps and directory guides. [The alignment map](../docs/jam-sync-alignment.md) accounts for each source idea, including the optional and design-only parts. These directories are source-ownership boundaries; their presence does not mean a subsystem has been implemented.

- `design/` records evolving intent, separating explicit user direction from AI-inferred proposals. `specs/` describes current reality and records the implementation revision reviewed. `TODO.md` holds deferred work. Plans and journals are optional and separate from all three.
- `docs/` holds contributor guidance; `research/` holds dated, source-backed investigations. `prototype/` holds visual targets and references, `prompts/` preserves exact directives and generation lineage, `marketing/` holds intentional promotional deliverables, and `artifacts/` holds working material according to its reproducibility.
- `vendored/` maps dependency ownership and provenance, including copied user-owned rope source snapshots. No newly licensed third-party dependency or root notices file exists yet. Add `THIRD_PARTY_NOTICES.md` separately at the root when attribution is needed.
- `tests/` owns verification, `tools/` owns creation utilities (`superscale`, `pixel_art/` including `import_bitwright.py`, `audio/` sound and music generators, `build/`), and `labs/` owns runnable technical comparisons. The pixel-scaling tool and lab share `scripts/art/` and diagnostic media under `assets/pixel_lab/`. The reusable rope lives under `scripts/rope/` with its own lab and focused spec. Other product source areas remain ready for the later game.
- `examples_agents/` contains portable instructions to adapt locally. `examples/` contains illustrations that are not accepted game design or actual generation records.

`scripts/physics/` and its focused spec own caller-authored solid/sensor parts and visual masks, with `shaders/occlusion_mask.gdshader` and a diagnostic lab. The component supplies no concrete game object or chosen collision box dimensions.

## Local and shared state

`AGENTS.md` at the root is tracked and shared by every contributor's agent; `CLAUDE.md` imports it with `@AGENTS.md`. It requires reading specs and design before a change, updating both compactly with it, and keeping explicit human direction (quoted in `prompts/source/`) separate from AI inference. Machine-specific rules stay in untracked notes. Tracked since 2026-09-25 at RaresKeY's request; before that both files were ignored.

`.gitignore` excludes engine caches, build/export output, local journals and scratch state, secrets files, and the reproducible `artifacts/tmp/` and `artifacts/generated/` buckets. It does not blanket-ignore `artifacts/`, visual candidates, or shared source. Preserve non-reproducible evidence and authored deliverables according to purpose, and review them before tracking. Reproducible release outputs are ephemeral under the owning release workflow.

`.gitattributes` normalizes text, pins Godot source and script formats to LF, and marks binary media as binary. `artifacts/.gdignore` prevents Godot from importing working outputs and captures. Tracked references use project-relative paths; machine installation details belong in environment variables or ignored local instructions.

## Collaboration and verification

The private GitHub `origin` is the collaboration remote. Contributors commit directly to `main`, rebase unpublished commits before every push, preserve work during conflicts, and recover with bisect and corrective commits. Experimental branches and external worktrees are optional. Pull requests and release tags are not used. Atomic ownership locks remain an optional future design; no lock manager or automatic recovery is implemented. No branch protection or access changes are part of this bootstrap.

README, collaboration guidance and the portable instruction example explicitly require fetching before push and rebasing if origin has advanced, including a push race. AI preserves all work through simple compatible conflicts. If that is impossible or the direction bifurcates, stop and ask the user before resolving or pushing; preserve both versions. The shared `AGENTS.md` carries the same policy.

Check Markdown links, the tracked/ignored boundary, Git attributes, and `git diff --check` after structure changes. Run `./tests/check` when engine sources or the check entry point change. Keep current behavior in specs and unfinished implementation work in `TODO.md`.
