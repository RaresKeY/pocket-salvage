# Pocket Salvage Specs Map

Reviewed: 2026-09-25. Implementation revision: `39312c3` (v0.1.7).

`specs/` is committed project memory for current intent and implementation. Read the relevant spec before changing its owning behavior, contract, boundary, source area, or verification flow, and update it with the implementation.

## Spec Map

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Project contract](project.md) | `project.godot`, `play.sh`, `labs/`, `tests/check`, `tests/README.md` | Implemented runtime and verification | Changing engine configuration, startup, or checks |
| [Scene preview](scene_preview.md) | `scenes/main.tscn`, `scripts/scene/`, contributed art | Yard composition, 8× textures, smooth inspection camera and scope | Arranging the game scene or changing preview layout |
| [Art specs module](art/_readme.md) | `assets/`, `scripts/art/`, `scripts/fx/`, `tools/pixel_art/`, `labs/pixel_scaling/`, project rendering defaults | Sampling conventions for all art and the exact-pixel tool/lab | Adding art, changing filtering/imports, or testing scaling |
| [Enlarged sprite playground](art/sprite_playground.md) | `assets/bitwright_8x/`, `labs/sprite_playground/` | 8× stored art, runtime filtering and grabbable physics fixture | Changing enlarged derivatives or sprite interaction |
| [Rope module](rope.md) | `scripts/rope/`, `labs/rope/`, `labs/shared/`, `vendored/rope_sources/` | Slack, tension, static wrapping, rendering, reuse and verification | Changing rope physics or the showcase |
| [Object physics and masks](physics.md) | `scripts/physics/`, `shaders/occlusion_mask.gdshader`, `labs/physics/` | Separate caller-authored solids, sensors and visual occlusion | Adding objects, masks or physics shapes |
| [Repository structure](repository.md) | `README.md`, directory guides, `.gitignore`, `.gitattributes`, `docs/`, `examples_agents/` | Source ownership, project memory, collaboration boundaries, and provenance | Changing the layout, contribution workflow, or file handling |
| [Crane suspension](crane.md) | `scripts/crane/`, `labs/crane/` | Rigid-body pivot, tension-only cable, load reaction and swappable heads | Integrating crane suspension or heads |
| [Sorting and rounds](round.md) | `scripts/round/`, `labs/sorting/` | Delivery sensors, scoring, timer and round lifecycle | Changing sorting or round rules |
| [Round HUD](round_hud.md) | `scripts/ui/`, `assets/fonts/`, `labs/hud/` | State-driven counters, square pixel theme, volume controls, feedback and modal actions | Changing round presentation |
| [Level selection](levels.md) | `scripts/level/level_catalog.gd`, `data/levels/` | Unlocked level grid and weather mapping | Changing playable levels |
| [Level layouts](level_layout.md) | `scripts/level/`, `labs/level/` | Prototype placements, backdrop, animated ambience and gulls | Changing layout fixtures or scenery |
| [Playable integration](salvage_prototype.md) | `labs/salvage/` | Combined crane, heads, sorting, round, UI, level and audio prototype | Changing playable integration or controls |
| [Weather](weather.md) | `scripts/weather/`, `data/weather/` | Per-round weather profiles, clock, and grip, wind, rain, fog and lightning effects | Changing or adding weather |
| [Audio](audio.md) | `scripts/audio/`, `tools/audio/`, `assets/audio/`, `labs/audio/`, `play.sh` | Effect pool, motor and music loops, generated placeholder sounds | Changing or replacing sounds |
| [Player input](input.md) | `scripts/input/`, `scripts/ui/touch_controller.gd`, playable integration, `tests/input_test.gd` | Device mappings, multi-touch ownership, focus and mobile detection | Changing controls or mobile Web input |
| [Standalone builds](builds.md) | `tools/build/`, `export_presets.cfg`, `.github/workflows/delivery.yml`, `tests/test_release.py`, `firebase.json`, `.firebaserc` | Clean-source exports, tag releases, reproducibility, Pages and manual Firebase hosting | Building the versioned prototype |

## Maintenance

- Keep specs compact, evidence-based, and current.
- Update this map when a spec is added, moved, split, or removed.
- Keep plans, TODOs, work logs, and merge handoffs outside `specs/`.
- Label planned behavior and open decisions; do not present them as implemented facts.
- Date each spec review and identify the implementation commit reviewed, rather than the documentation-only commit that records the review.
