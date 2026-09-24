# Pocket Salvage Specs Map

Reviewed: 2026-09-24. Implementation revision: `fe746e2`. Reference conventions: Jam Sync `d2c801a`, with the user's direct-main collaboration rules.

`specs/` is committed project memory for current intent and implementation. Read the relevant spec before changing its owning behavior, contract, boundary, source area, or verification flow, and update it with the implementation.

## Spec Map

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Project contract](project.md) | `project.godot`, `labs/`, `tests/check`, `tests/README.md` | Implemented runtime and verification | Changing engine configuration, startup, or checks |
| [Art specs module](art/_readme.md) | `assets/`, `scripts/art/`, `tools/pixel_art/`, `labs/pixel_scaling/`, project rendering defaults | Sampling conventions for all art and the exact-pixel tool/lab | Adding art, changing filtering/imports, or testing scaling |
| [Rope module](rope.md) | `scripts/rope/`, `labs/rope/`, `labs/shared/`, `vendored/rope_sources/` | Slack, tension, static wrapping, rendering, reuse and verification | Changing rope physics or the showcase |
| [Object physics and masks](physics.md) | `scripts/physics/`, `shaders/occlusion_mask.gdshader`, `labs/physics/` | Separate caller-authored solids, sensors and visual occlusion | Adding objects, masks or physics shapes |
| [Repository structure](repository.md) | `README.md`, directory guides, `.gitignore`, `.gitattributes`, `docs/`, `examples_agents/` | Source ownership, project memory, collaboration boundaries, and provenance | Changing the layout, contribution workflow, or file handling |

## Maintenance

- Keep specs compact, evidence-based, and current.
- Update this map when a spec is added, moved, split, or removed.
- Keep plans, TODOs, work logs, and merge handoffs outside `specs/`.
- Label planned behavior and open decisions; do not present them as implemented facts.
- Date each spec review and identify the implementation commit reviewed, rather than the documentation-only commit that records the review.
