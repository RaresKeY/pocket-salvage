# Random Game — Example Local Instructions

Adapt these rules into a local `AGENTS.md` or `CLAUDE.md`; add your own environment constraints. This example is portable guidance, not an automatically loaded instruction file.

- Read `specs/_readme.md` and relevant specs before editing. Update specs alongside implementation, recording the review date and implementation commit reviewed.
- Read `design/_readme.md` before adding behavior. Separate explicit user input and contributor decisions from AI-inferred proposals. The game concept and art direction remain undecided.
- Use `TODO.md` for deferred work. Plans and journals are optional and separate from implementation specs.
- Commit directly to `main` in your own clone; use experimental branches or external worktrees only when separation helps. Follow `docs/collaboration.md`. Preserve unfinished work; automatic task/lane locks are not implemented or required.
- Before every push to private GitHub `origin`, fetch and rebase unpublished commits onto the current remote, resolve compatible conflicts, inspect, and validate. Push normally without PRs or release tags. Preserve shared history and use bisect plus corrective/revert commits for recovery.
- Keep all work during conflicts. Let AI resolve compatible edits; ask contributors when intent conflicts. Do not change hosting or collaborator access without a user request.
- Private reproducible builds use `0.0.0+<short-sha>` from clean committed source. Assign explicit in-game release versions only for public builds; SHA stamping is not implemented yet. Start with a shared design spike before implementing the MVP.
- Run `./tests/check` for engine-affecting changes; add meaningful behavior checks as the game grows. Report actual results and limitations. Fix failures instead of weakening checks.
- Follow your local execution rules. On the shared workstation, use the managed Godot Podman runner; use background Gamescope for automated visuals and verify the actual renderer. Headless startup does not establish rendering quality.
- Choose the style in `design/` before generating images. Preserve source directives, exact prompts, references, outputs, and selection status through `prompts/` and `prototype/`. Treat Trellis models as experimental candidates.
- Read `specs/art/_readme.md` before importing or displaying art. Use `labs/pixel_scaling/` to compare sampling and `tools/superscale` for exact integer PNG enlargement. Diagnostic lab styling does not select the game's art direction.
- Keep provenance under `vendored/` and third-party notices separately at the root when needed. Keep runtime sources, creation tools, tests, and promotional material in their documented areas.
- Use project-relative references. Keep machine-specific state, credentials, private keys, sensitive raw logs, and reproducible outputs out of tracked files. Preserve authored source and non-reproducible evidence.
- Prototype and orchestrate in Python; profile before optimizing measured bottlenecks in native code. Do not add a project license without explicit direction.
