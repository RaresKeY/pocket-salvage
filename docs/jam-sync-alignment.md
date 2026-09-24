# Jam Sync Alignment

Reference: the user's `jam-sync` repository at `d2c801a`, reviewed 2026-09-24, especially `README.md`, `.gitattributes`, `examples_agents/jam-sync.md`, and `examples/visual-style.md`. This is a structural adaptation of those conventions, not a claim that the reference installs tooling.

The user's later [collaboration rules](../prompts/source/collaboration-rules.md) take precedence: direct commits to `main`, experimental branches only when useful, rebase before push, no PRs or release tags, and SHA-based private-build identity. Jam Sync's advanced worktree coordination remains optional.

| Jam Sync idea | Location here | Bootstrap status |
|---|---|---|
| Evolving design, document map, and user/AI attribution | [design map](../design/_readme.md), [game direction](../design/game.md) | Present; gameplay remains undecided. |
| Implemented reality, map, review date, and source revision | [specs map](../specs/_readme.md) | Present; reviewed implementation revisions are recorded near the top. |
| Deferred project work | [TODO.md](../TODO.md) | Short prerequisite-based list. |
| Optional journals and separate plans | [collaboration guide](collaboration.md) | Purpose documented; no required folders or format. |
| Supporting documentation and research | [docs](README.md), [research](../research/README.md) | Separate ownership guides; no research claims yet. |
| Cohesive style selected before generation | [visual direction](../design/visual-style.md) | Decision boundary present; no style selected. |
| Visual mockups, references, comparison, and selection | [prototype](../prototype/README.md) | Candidate/reference layout documented; no generated visuals. |
| Exact source directives, prompts, revisions, and lineage | [prompts](../prompts/README.md), [source directives](../prompts/source/repository-bootstrap.md) | Directives preserved; generation prompts and inventory await actual use. |
| Experimental Trellis 3D candidates | [prototype](../prototype/README.md), [assets](../assets/README.md) | Evaluation boundary documented; no models generated. |
| Promotional deliverables versus temporary work | [marketing](../marketing/README.md), [artifacts](../artifacts/README.md) | Separate homes and retention rules. |
| Dependency map, provenance, and separate root notices | [vendored map](../vendored/_readme.md) | Map present; no dependencies or notices needed yet. |
| Tests and project-relative test inputs | [tests](../tests/README.md) | Existing check moved from `tools/check` to `tests/check`. |
| One-shot creation tools | [tools](../tools/README.md) | Reserved for actual creation utilities. |
| Shared source versus local/generated outputs | [.gitignore](../.gitignore), [artifacts](../artifacts/README.md) | Generated buckets ignored; authored and non-reproducible material considered separately. |
| Portable references | [repository contract](../specs/repository.md), [tests/check](../tests/check) | Project-relative documentation; runner override or sibling lookup. |
| Godot text/LF rules and explicit binary attributes | [.gitattributes](../.gitattributes) | Applied to Godot sources, scripts, and media. |
| Local ignored agent instructions | [.gitignore](../.gitignore), [instruction examples](../examples_agents/README.md) | `AGENTS.md` and `CLAUDE.md` excluded; existing local instructions preserved. |
| Reusable instruction examples | [random-game example](../examples_agents/random-game.md) | Portable guidance tracked separately from machine policy. |
| Clearly labeled convention examples | [examples](../examples/README.md), [visual-style example](../examples/visual-style.md) | Illustration only; not approved art or an actual prompt record. |
| External owned worktree lanes and separate atomic locks | [collaboration design](../design/collaboration.md) | Design-only; no locking tool installed. |
| Preserve dirty/failed work and recover ownership explicitly | [collaboration guide](collaboration.md), [coordination design](../design/collaboration.md) | Manual preservation rules and proposed recovery contract. |
| Commit/validation handoff and serial integration | [collaboration guide](collaboration.md) | Direct pushes with fetch/rebase/recheck when another contributor advances `main`. |
| Source isolation versus container execution | [coordination design](../design/collaboration.md), [tests](../tests/README.md) | Distinction explicit; shared runner handles engine execution. |
| Optional product-source separations | [scenes](../scenes/README.md), [scripts](../scripts/README.md), [assets](../assets/README.md), [data](../data/README.md), [shaders](../shaders/README.md), [native](../native/README.md) | Ownership guides present; the game is still empty, while shared scaling code and diagnostic media support the lab. |

The user subsequently requested a technical art experiment under [labs/](../labs/README.md), with a nested [art specs module](../specs/art/_readme.md). Its calibration chart is diagnostic source, not generated or selected game art.

No license, external dependency, game design, generated art, or automatic coordination system is introduced by this structure bootstrap.
