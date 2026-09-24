# Verification

Run `./tests/check` from the repository root on the shared workstation. The script only orchestrates the managed Godot Podman runner; engine execution happens inside one ephemeral managed container. It resolves a sibling `godot-podman` checkout or the `GODOT_PODMAN_RUNNER` override, preserves the hardware-access default, and opens no desktop window.

`run_checks.py` imports the project, verifies exact pixel blocks and alpha, exercises the scaling CLI and provenance, tests lab controls, and runs a two-frame startup. It bounds child processes and rejects logged script errors or missing success markers. This is neither gameplay coverage nor visual/hardware-renderer proof. Other environments can use the equivalent suite in [README.md](../README.md), subject to their local execution rules.

Use [the background capture flow](../labs/pixel_scaling/README.md) for hardware-rendered comparisons. Its image metadata records when an on-screen native-integer/baked comparison was actually checked; offscreen pairs are not counted as proof.

`rope_test.gd` checks actual slack, tension and wrapped-route behavior as well as renderer isolation. The suite also runs the rope lab for 120 physics ticks. Use `./labs/capture rope` for its separate hardware-rendered check. Refer to tests and input files with project-relative paths, so records remain useful across machines and worktree lanes. Full timed-round gameplay is not implemented yet.

`physics_parts_test.gd` checks real ray hits, filtered Area2D overlap, private shape ownership, independently enabled parts, and visual-mask material lifetime. The physics lab startup is also checked. `./labs/capture physics` verifies rendered alpha and observes contacts/sensors on the GPU. Its boxes are diagnostic fixtures, not game object definitions.

`sprite_playground_test.gd` verifies all 75 exact 8× derivatives and provenance, gallery count, gravity/floor collision, matching sprite/collision size, filtering, mouse picking/grab/release and reset. `./labs/capture sprite_playground` supplies separate GPU captures.
`yard_camera_test.gd` checks the scene’s enlarged texture bindings, tile regions, native viewport, smooth pointer-anchored zoom, limits, left/middle panning, release/focus cancellation, reset and resize.
