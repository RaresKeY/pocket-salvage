# Verification

Run `./tests/check` from the repository root on the shared workstation. The script only orchestrates the managed Godot Podman runner; engine execution happens inside one ephemeral managed container. It resolves a sibling `godot-podman` checkout or the `GODOT_PODMAN_RUNNER` override, preserves the hardware-access default, and opens no desktop window.

`run_checks.py` imports the project, verifies exact pixel blocks and alpha, exercises the scaling CLI and provenance, tests lab controls, and runs a two-frame startup. It bounds child processes and rejects logged script errors or missing success markers. This is neither gameplay coverage nor visual/hardware-renderer proof. Other environments can use the equivalent suite in [README.md](../README.md), subject to their local execution rules.

Use [the background capture flow](../labs/pixel_scaling/README.md) for hardware-rendered comparisons. Its image metadata records when an on-screen native-integer/baked comparison was actually checked; offscreen pairs are not counted as proof.

Add meaningful behavior-specific tests and fixtures here as the game grows. Refer to tests and input files with project-relative paths, so records remain useful across machines and worktree lanes. No gameplay tests exist yet.
