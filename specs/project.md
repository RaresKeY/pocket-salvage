# Project Contract

Reviewed: 2026-09-25. Implementation: mobile-overlay change based on `285719e`.

## Status and scope

Pocket Salvage is the official game name; its public GitHub repository is `RaresKeY/pocket-salvage`. The selected loop is a magnetic crane collecting and sorting scrap before time expires. Godot 4.7 opens the level grid in `labs/salvage/lab.tscn`. The static yard preview remains a separately openable source scene; gameplay has no preview navigation. Technical labs remain separate runnable scenes. That lab implements a crane with swappable magnet and claw heads and two tool stands, a level-dependent physical scrap heap (4/6/10/12 pieces), three wall-sharing bins with throw-back on a wrong sort, scoring with a time bonus, a 240-second timer, pause/results/restart, animated night scenery and generated audio. Bin-front masking and final gameplay integration remain open. Final art direction remains open. Public delivery covers Windows, Linux and Web; native target-machine verification is recorded separately.

## Source ownership

- `project.godot` owns engine features, project identity, startup scene, and renderer settings.
- `scenes/main.tscn` owns the editable yard composition; `scripts/scene/yard_preview.gd` owns its smooth inspection camera and native HUD.
- `labs/pixel_scaling/` owns the standalone scaling lab; [the art module](art/_readme.md) owns its scaling/filtering contract and related creation tool.
- `scripts/rope/` and `labs/rope/` own the [rope subsystem and showcase](rope.md); `vendored/rope_sources/` preserves original copied source.
- `scripts/physics/`, `shaders/occlusion_mask.gdshader` and `labs/physics/` own [separate visual mask, solid and sensor capabilities](physics.md). Concrete geometry lives in prototype callers rather than the reusable physics components.
- `play.sh` resolves its source checkout, imports current local assets and launches the configured project main scene through the managed runner, with hardware GPU access and real desktop audio. Import and play share one project lock; extra arguments pass unchanged to Godot. See [audio](audio.md).
- `tests/check` runs `tests/run_checks.py` through the external shared Godot Podman runner. It resolves the runner from a sibling checkout or `GODOT_PODMAN_RUNNER`.
- `scripts/crane/`, `scripts/round/`, `scripts/ui/`, `scripts/level/`, `scripts/fx/`, `scripts/art/yard_art.gd`, `scripts/audio/` and `labs/salvage/` own the playable prototype; see the [specs map](_readme.md).
- [Repository structure](repository.md) describes project memory, collaboration, file handling, and the source layout.

## Collaboration contract

The public GitHub repository uses direct commits to `main`, rebasing unpublished work onto the latest remote before pushing. Experimental branches are optional; pull requests are not part of the current workflow; release tags are permitted for explicitly requested GitHub releases. The [collaboration guide](../docs/collaboration.md) owns conflict, recovery, and build-identity rules. Optional future coordination automation lives in [design](../design/collaboration.md).

`project.godot` declares version `0.1.5`, the assistant-selected patch version for the requested release. No project license has been selected.

Physics runs at 60 Hz with native 2D physics interpolation enabled. Physical bodies and the hoist move on physics ticks; custom cable geometry interpolates its previous/current particle positions at render cadence without modifying the solver. Explicit restart/spawn teleports reset interpolation history.

## Verification

`./tests/check` runs editor import, exact-pixel and CLI tests, lab control checks, and a two-frame headless startup in one managed container. Each child process has a timeout; script errors and missing success markers fail the suite. These checks do not establish gameplay correctness, visual quality, or hardware rendering. The separate background GPU capture flow is described in [the lab spec](art/pixel_scaling.md).

Documentation changes require checking map links, source references, and the Git diff. Future gameplay needs behavior-specific checks as it is implemented.

Player input is shared through `scripts/input/salvage_input.gd`; [input](input.md) owns keyboard/gamepad mappings and mobile touch controls. Minimum window dimensions are 320×320; phone layout is validated separately from desktop. Gamepad events are ignored while the application is unfocused.

Web exports cap presentation at 60 FPS through `application/run/max_fps.web`; native builds retain the platform/VSync rate. Physics remains 60 Hz with interpolation. The cap avoids chasing a 165 Hz desktop refresh when the Web frame budget cannot reliably sustain it.


Current release version is 0.1.7: curved wind and sparse dust, square pixel-font UI and independent pause-menu volumes from `53982f2`, with local Developer controls hidden in exports.

`play-mobile.sh` adds a Linux phone-layout preview of current local source, with mouse-operated analog touch controls. See [input](input.md).
