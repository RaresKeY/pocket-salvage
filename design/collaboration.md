# Collaboration Design

## User design

The user selected direct commits to `main`, optional experimental branches, continuous spec synchronization, checkpoints as useful, rebase before every push, no release tags, and recovery through bisect and corrective commits. Work is freeform and asynchronous, starting with a shared design spike before an MVP. Preserve all work during conflicts; AI can resolve compatible edits, while conflicting intent needs contributor agreement. See [the exact directives](../prompts/source/collaboration-rules.md).

Jam Sync's owned-worktree and locking ideas remain an optional future design. They do not impose mandatory task branches or integration ceremony on this experiment.

## AI-inferred design

Use independent clones for ordinary concurrent work on `main`. Reach for experimental branches and external worktree lanes only when isolation helps. [The contributor guide](../docs/collaboration.md) describes the current direct-push workflow. A lane means an external Git worktree assigned to one contributor and task.

## Optional future ownership contract

- Acquire the task and lane atomically before preparing a clean worktree. Keep task locks separate from lane locks; use a separate integration lock to serialize merges.
- Record the owner, task, branch, base commit, and ownership token. A PID alone cannot establish ownership or staleness.
- Preserve unfinished and failed work. Never reset a lane simply to reuse it. Investigate ownership and worker state before explicitly recovering a stale lock.
- Preserve commits, validation results, and a handoff before releasing a lane. The designated integrator reviews one branch at a time, updates specs, resolves conflicts, and validates the combined result.
- Worktrees isolate source changes. Containers provide the execution boundary; the Godot runner's project lock does not implement task/lane ownership or coordinate separate worktrees.

The storage format, lock implementation, stale-worker checks, and recovery commands remain undecided. Do not claim automatic protection until those mechanisms are implemented and verified.
