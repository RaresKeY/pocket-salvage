# Pocket Salvage Specs Map

Reviewed: 2026-09-24 integrating the scene preview with the physics components and 8× sprite playground.

`specs/` is committed project memory for current intent and implementation. Read the relevant spec before changing its owning behavior, contract, boundary, source area, or verification flow, and update it with the implementation.

## Spec Map

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Project contract](project.md) | `project.godot`, `labs/`, `tests/check`, `tests/README.md` | Implemented runtime and verification | Changing engine configuration, startup, or checks |
| [Scene preview](scene_preview.md) | `scenes/main.tscn`, `scripts/scene/`, contributed art | Static yard composition, integer presentation and scope | Arranging the game scene or changing preview layout |
| [Art specs module](art/_readme.md) | `assets/`, `scripts/art/`, `tools/pixel_art/`, `labs/pixel_scaling/`, project rendering defaults | Sampling conventions for all art and the exact-pixel tool/lab | Adding art, changing filtering/imports, or testing scaling |
| [Enlarged sprite playground](art/sprite_playground.md) | `assets/bitwright_8x/`, `labs/sprite_playground/` | 8× stored art, runtime filtering and grabbable physics fixture | Changing enlarged derivatives or sprite interaction |
| [Rope module](rope.md) | `scripts/rope/`, `labs/rope/`, `labs/shared/`, `vendored/rope_sources/` | Slack, tension, static wrapping, rendering, reuse and verification | Changing rope physics or the showcase |
| [Object physics and masks](physics.md) | `scripts/physics/`, `shaders/occlusion_mask.gdshader`, `labs/physics/` | Separate caller-authored solids, sensors and visual occlusion | Adding objects, masks or physics shapes |
| [Repository structure](repository.md) | `README.md`, directory guides, `.gitignore`, `.gitattributes`, `docs/`, `examples_agents/` | Source ownership, project memory, collaboration boundaries, and provenance | Changing the layout, contribution workflow, or file handling |

## Maintenance

- Keep specs compact, evidence-based, and current.
- Update this map when a spec is added, moved, split, or removed.
- Keep plans, TODOs, work logs, and merge handoffs outside `specs/`.
- Label planned behavior and open decisions; do not present them as implemented facts.
- Date each spec review and identify the implementation commit reviewed, rather than the documentation-only commit that records the review.
