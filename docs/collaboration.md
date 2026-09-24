# Working Together

## Local setup

Read [the specs map](../specs/_readme.md) and relevant specs before editing. Read [the design map](../design/_readme.md) before proposing new behavior. Adapt [the repository instruction example](../examples_agents/random-game.md) into your own ignored `AGENTS.md` or `CLAUDE.md`, adding your environment's execution and resource constraints.

The collaboration remote is private GitHub `origin`. Access requires a separate invitation; this bootstrap does not grant access or install branch protection.

## Current manual workflow

1. Agree on one task and its owner. Use a focused `feature/<topic>` or `fix/<topic>` branch from current `main` in a separate clone or worktree.
2. For parallel work, prefer stable worktree lanes outside the repository. Agree on ownership before use. Only prepare a clean lane; preserve unfinished or failed work. Automatic ownership locks are not implemented.
3. Keep code and its matching specs together. Preserve explicit user design separately from AI inference. Put deferred work in `TODO.md`; use optional local journals or plans only when useful.
4. Run relevant checks, preserve the resulting commits, and open a pull request into `main`. State the behavior change, verification, limitations, and any handoff the integrator needs. Never share a dirty checkout between concurrent workers.
5. A designated integrator reviews and merges one branch at a time, resolves conflicts, and validates the combined result. Preserve task commits, validation results, and handoff before releasing a lane. Do not reset or delete someone else's unfinished work.

There is no permanent `develop` branch or release branch at this stage. Introduce release tags and release-specific checks when an actual release workflow exists.

## Proposed automation

[The collaboration design](../design/collaboration.md) defines task, lane, and integration locks; ownership tokens; and explicit stale-lock recovery. Until implemented, coordinate manually. Worktree separation and the engine runner's project lock are not substitutes for those ownership checks.

## Execution and records

Use [tests/](../tests/README.md) for verification and [tools/](../tools/README.md) for one-shot creation utilities. Follow local execution rules; on the shared workstation, use the managed Godot Podman runner. Worktrees and containers provide different boundaries. Use project-relative references in shared material and keep machine details in local configuration.

Journals are optional working memory. Plans are optional implementation preparation. Neither belongs in specs or replaces `TODO.md`; no shared format or directory is required.
