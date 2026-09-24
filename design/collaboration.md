# Collaboration Design

## User design

The requested Jam Sync alignment includes its preferred worktree workflow: one task branch per owned lane outside the repository, atomic task and lane ownership, serial integration, explicit stale-lock recovery, and preserved task evidence. This is a coordination design, not an installed tool.

## AI-inferred design

Use the existing manual branch-and-pull-request workflow while the team decides whether to implement automation. [The contributor guide](../docs/collaboration.md) describes what can be done now. A lane means an external Git worktree assigned to one contributor and task.

## Proposed ownership contract

- Acquire the task and lane atomically before preparing a clean worktree. Keep task locks separate from lane locks; use a separate integration lock to serialize merges.
- Record the owner, task, branch, base commit, and ownership token. A PID alone cannot establish ownership or staleness.
- Preserve unfinished and failed work. Never reset a lane simply to reuse it. Investigate ownership and worker state before explicitly recovering a stale lock.
- Preserve commits, validation results, and a handoff before releasing a lane. The designated integrator reviews one branch at a time, updates specs, resolves conflicts, and validates the combined result.
- Worktrees isolate source changes. Containers provide the execution boundary; the Godot runner's project lock does not implement task/lane ownership or coordinate separate worktrees.

The storage format, lock implementation, stale-worker checks, and recovery commands remain undecided. Do not claim automatic protection until those mechanisms are implemented and verified.
