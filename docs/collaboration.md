# Working Together

## Local setup

Read [the specs map](../specs/_readme.md) and relevant specs before editing. Read [the design map](../design/_readme.md) before proposing new behavior. Adapt the [portable instruction example](../examples_agents/random-game.md) into your local `AGENTS.md`; a local `CLAUDE.md` may import it. Both root files are ignored and untracked.

The collaboration remote is public GitHub `origin`, `RaresKeY/pocket-salvage`. Reading needs no invitation; pushing still requires collaborator access.

## Current manual workflow

The user's direct-commit rules supersede the initial bootstrap's pull-request workflow. Keep collaboration freeform and asynchronous: agree on the design first, then implement a small MVP as contributors have time.

1. Work on `main` in your own clone. Use an experimental branch and separate worktree only when isolation is useful. Never share a dirty checkout between concurrent workers.
2. Make focused commits and checkpoints as needed. Keep matching specs synchronized, separate explicit user design from AI inference, and record deferred work in `TODO.md`.
3. Before each push, commit the work being preserved, fetch the latest remote, and rebase unpublished commits onto it. Resolve conflicts, inspect the resulting diff, and run relevant checks. Push normally; if another contributor has pushed first, fetch and rebase again.
4. Push directly to `main`, with verification and limitations recorded in commit messages or the handoff. No pull requests or mandatory feature branches. Release tags are reserved for explicitly requested GitHub releases. Preserve published history; do not force-push shared `main`.

The normal sequence after making local commits is:

```sh
git fetch origin
git rebase origin/main
# Inspect the combined change and run the relevant checks before pushing.
git push origin main
```

Configure `git config --local pull.rebase true` in each clone so ordinary pulls also rebase. That setting does not automatically fetch or rebase when pushing; the pre-push sequence remains explicit.

## Conflicts and recovery

Keep all contributors' work. AI should resolve simple compatible conflicts while retaining both intentions; inspect the combined result and rerun relevant checks. If AI cannot preserve all work, or the direction is bifurcating, **stop and ask the user for direction before resolving or pushing**. Preserve both versions and local commits. Abort an in-progress rebase if necessary to return to that preserved state; never silently choose a side or discard work just to make a push succeed. Always fetch before pushing and rebase whenever `origin/main` has advanced, including after a rejected push race.

Use `git bisect` to locate regressions and add a corrective or revert commit on top. Checkpoints provide recovery points; they are not release markers. Add a more elaborate coordination policy only if actual conflicts make it necessary.

## Build identity

Ordinary development does not automatically increment release versions. Build from a clean committed source tree, resolving the source SHA after rebasing. Do not identify dirty source as an unchanged commit build.

The user explicitly requested prototype version `0.1.0`; `project.godot` supplies the in-game label. The [build script](../specs/builds.md) records the full source commit and toolchain hashes in each candidate manifest and verifies repeat builds on request. Release tags are created only when the user explicitly requests a GitHub release. Keep the current requested candidate locally and generated outputs ephemeral otherwise.

## Repository migration

The repository was renamed from `random-game` to `pocket-salvage` and made public on 2026-09-25. GitHub redirects the old Git URL, but update existing clones explicitly:

```sh
git remote set-url origin https://github.com/RaresKeY/pocket-salvage.git
```

Before pulling the removal commit, copy `AGENTS.md` and `CLAUDE.md` outside your checkout, then restore them after the pull. Git removes unchanged tracked copies when applying their deletion; modified copies may block the pull. They become ignored local files afterward. You can also recreate them from the portable example. Their earlier revisions remain in Git history; this change does not rewrite history. Existing clones need not rename their local directory. At RaresKeY’s later request, the workstation’s main checkout was renamed to `pocket-salvage`, with Git links repaired for the existing sibling worktrees.

`gh-pages` contains generated site files and deployment history only; never merge it into main. Pushed release tags now run the [delivery workflow](../specs/builds.md). Existing collaborator grants remain intact; the rename does not require a fresh clone.

## Proposed automation

[The collaboration design](../design/collaboration.md) retains Jam Sync's task, lane, and integration lock ideas as optional future work. They are neither installed tooling nor a prerequisite for this experiment. Worktree separation and the engine runner's project lock are not substitutes for ownership checks.

## Execution and records

Use [tests/](../tests/README.md) for verification and [tools/](../tools/README.md) for one-shot creation utilities. Follow local execution rules; on the shared workstation, use the managed Godot Podman runner. Worktrees and containers provide different boundaries. Use project-relative references in shared material and keep machine details in local configuration.

Journals are optional working memory. Plans are optional implementation preparation. Neither belongs in specs or replaces `TODO.md`; no shared format or directory is required.
