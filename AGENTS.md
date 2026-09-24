# Project Agent Guidance

Read `specs/_readme.md` and the relevant focused specs before changing project behavior. Keep specs synchronized with implementation in the same change.

This is a Godot 4.7 collaboration experiment. The game concept is undecided; follow the user's next direction before adding gameplay or a visual theme.

Use short-lived `feature/<topic>` or `fix/<topic>` branches for focused changes. Keep `main` usable and submit pull requests into it. Keep related source and spec changes together in coherent commits. Each concurrent contributor should use a separate clone or worktree; preserve other contributors' work.

The private GitHub repository is the collaboration remote, named `origin`. Do not create additional hosting mirrors or change collaborator access without a user request.

Run `./tools/check` for engine-affecting changes. Add meaningful verification as behavior grows. State which checks ran and any limitations. Documentation-only changes need link and diff review.

On the shared workstation, use the shared `godot-podman` wrapper for containerized engine work. Preserve its hardware GPU default. Automated visual runs must use Gamescope's headless backend and verify the actual renderer; headless import/startup output is not hardware-renderer proof. Open desktop windows only when requested.

Keep local journals and scratch files under ignored `.local/`. Keep build and export outputs ephemeral, and create release artifacts only for an authorized release workflow. Do not commit credentials, private keys, or raw sensitive logs. Do not add a project license without the user's direction.
