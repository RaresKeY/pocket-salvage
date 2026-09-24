# Rope source provenance

Copied on 2026-09-24 before extraction, at the user's request, from their existing projects. Snapshots are references, excluded from Godot import by `.gdignore`; the executable adaptation is `scripts/rope/`. No external clone, Git submodule initialization or package installation is required.

| Source | Copied code | Revision |
|---|---|---|
| White Approach (`fog-mountain`) | Complete `scripts/rope.gd` and `scripts/rope_path.gd` | `909afd7bd778b0c549246ab03d2784a10cdaef77` |
| Plug & Prosper (`plug-charge`) | Constants, initialization/Verlet solver, adaptive curve and jacket functions from `game/main.gd` | `df26cc5d654aa0bd454387f8427df38ff16967f7` |

[provenance.json](provenance.json) records source and snapshot SHA-256 hashes, line ranges for the excerpt and source-file modification status. All selected files matched their committed revisions; unrelated untracked UID files in White Approach were not copied. The excerpt retains original code and includes range comments; it is not a standalone script.

Selection: White Approach is the more developed **physical rope**, with extension-only constraints, swept contacts and persistent terrain routing. Plug & Prosper is the more developed **drawing**, with adaptive midpoint curves and capped folds. Its cable solver is more coupled to game dictionaries and fixed-length plug behavior, so it remains reference material. No cross-project performance comparison was made.

Adaptations: remove grappling-hook/player/chapter logic; accept explicit closed static polygons rather than mountain strips closed at y=1200; inject sweeps into the solver; expose endpoint tension separately; retain each pinned contact when smoothing. Hook flight and cable-current particles were intentionally not extracted.

These are private user-owned source copies; no new license or redistribution grant is asserted. Preserve provenance on future reuse. To update, inspect both upstream implementations, replace snapshots and hashes deliberately, review local adaptations, and run rope behavior tests and the rendered lab. Never blindly overwrite the adapted module.
