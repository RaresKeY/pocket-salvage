# Rope subsystem

Reviewed: 2026-09-24. Implementation revision: `a4a329e`; upstream revisions and hashes are in [provenance](../vendored/rope_sources/provenance.json).

`scripts/rope/` is an in-repository reusable 2D subsystem, not an external Git dependency. `rope_solver.gd` owns Verlet particles, eight alternating tension-only constraint passes, slack initialization, fixed endpoints and swept contacts. `rope_path.gd` owns static polygon visibility and persistent convex-corner guides. `rope_render.gd` owns Plug & Prosper's adaptive midpoint curves (0.30 authored pixel target, at most six subdivisions) and rounded folds. `rope_2d.gd` binds world-space ray queries and drawing. Endpoints and pinned contacts remain exact; render geometry never feeds back into physics.

Caller contract: fixed 60 Hz stepping; world-space endpoints and closed static collision polygons; endpoint bodies remain outside solids. `constrain_tip` removes only outward radial velocity and returns a proposed positional correction. Apply that through collision-aware body motion before calling `step`; a visual rope alone never moves a load. A geometry-blocked reel reports `blocked`. Collision masks/exclusions are configurable. No self-collision, moving-surface wrapping, stretch elasticity, load mass feedback or 3D physics. Smoothed slack spans may visually depart from contact particles by a few pixels; this is not collision geometry.

`labs/rope/` is the standalone interactive showcase, using `labs/shared/lab_page.gd` for responsive controls, viewport fitting and bounded capture. The scrapyard preview is the startup scene; the rope and pixel labs remain separately runnable. Art filtering conventions are unchanged; antialiased procedural cable lines are distinct from pixel-texture sampling.

Verification: `tests/rope_test.gd` checks sag, exact endpoints, finite geometry, no render mutation, taut response, tangential momentum, wrapped routes, contact persistence and unwrapping. `tests/run_checks.py` imports the module and starts the lab. `labs/capture rope` produces background hardware-rendered evidence separately. These are subsystem checks, not full-game or performance acceptance.

2026-09-24 validation: the complete check suite passes, including `rope_lab_test.gd` viewport fitting, keyboard reeling, pause/resume and reset. Background Gamescope captures were inspected at 1920×1080, 1280×720, 960×540 and 854×480 using Godot 4.7 / NVIDIA GeForce RTX 2080 Ti. No physical-device, gamepad, touch or full-game performance claim is made.
