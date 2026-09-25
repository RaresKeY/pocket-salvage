# Pocket Salvage — Example Local Instructions

Copy or adapt this portable example into local `AGENTS.md`; local `CLAUDE.md` can contain `@AGENTS.md`. Both root files are ignored. The filename of this example preserves its original reference path; the public repository is now `pocket-salvage`.

- Read `specs/_readme.md` and relevant specs before editing. Update specs alongside implementation, recording the review date and implementation commit reviewed.
- Read `design/_readme.md` before adding behavior. Separate explicit user input and contributor decisions from AI-inferred proposals. Pocket Salvage uses a magnetic crane to collect and sort scrap before time expires. The public repository/upstream is `pocket-salvage`; final art direction remains undecided.
- Use `TODO.md` for deferred work. Plans and journals are optional and separate from implementation specs.
- Commit directly to `main` in your own clone; use experimental branches or external worktrees only when separation helps. Follow `docs/collaboration.md`. Preserve unfinished work; automatic task/lane locks are not implemented or required.
- Before every push to GitHub `origin`, fetch and rebase unpublished commits onto the current remote, resolve compatible conflicts, inspect, and validate. Push normally without PRs. Explicitly requested stable release tags trigger tests, builds, GitHub Releases and Pages. Preserve shared history and use bisect plus corrective/revert commits for recovery.
- Always keep all work during conflicts. AI should resolve simple compatible edits while preserving both intentions. If AI cannot preserve all work or the direction is bifurcating, stop and ask the user for direction before resolving or pushing. Preserve both versions; never silently choose a side. If origin advances before a push succeeds, fetch and rebase again. Do not change hosting or collaborator access without a user request.
- Build only from clean committed source. `project.godot` owns the release version; the manifest records the source SHA and toolchain hashes. Start with a shared design spike before implementing the MVP.
- Run `./tests/check` for engine-affecting changes; add meaningful behavior checks as the game grows. Report actual results and limitations. Fix failures instead of weakening checks.
- Follow your local execution rules. On the shared workstation, use the managed Godot Podman runner; use background Gamescope for automated visuals and verify the actual renderer. Headless startup does not establish rendering quality.
- Choose the style in `design/` before generating images. Preserve source directives, exact prompts, references, outputs, and selection status through `prompts/` and `prototype/`. Treat Trellis models as experimental candidates.
- Read `specs/art/_readme.md` before importing or displaying art. Use `labs/pixel_scaling/` to compare sampling and `tools/superscale` for exact integer PNG enlargement. Diagnostic lab styling does not select the game's art direction.
- Keep provenance under `vendored/` and third-party notices separately at the root when needed. Keep runtime sources, creation tools, tests, and promotional material in their documented areas.
- Use project-relative references. Keep machine-specific state, credentials, private keys, sensitive raw logs, and reproducible outputs out of tracked files. Preserve authored source and non-reproducible evidence.
- Prototype and orchestrate in Python; profile before optimizing measured bottlenecks in native code. Do not add a project license without explicit direction.
