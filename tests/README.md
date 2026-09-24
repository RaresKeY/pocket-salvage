# Verification

Run `./tests/check` from the repository root on the shared workstation. The script only orchestrates the managed Godot Podman runner; engine execution happens inside one ephemeral managed container. It resolves a sibling `godot-podman` checkout or the `GODOT_PODMAN_RUNNER` override, preserves the hardware-access default, and opens no desktop window.

The current checks import the project in the editor and start the empty main scene for two headless frames. Inspect output for engine errors as well as the process exit status. This is neither gameplay coverage nor visual/hardware-renderer proof. Other environments can use the equivalent Godot 4.7 commands in [README.md](../README.md), subject to their local execution rules.

Add meaningful behavior-specific tests and fixtures here as the game grows. Refer to tests and input files with project-relative paths, so records remain useful across machines and worktree lanes. No gameplay tests exist yet.
