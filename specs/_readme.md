# Random Game Specs Map

Reviewed: 2026-09-24. Implementation revision: `be7e1eb`. Reference conventions: Jam Sync `d2c801a`.

`specs/` is committed project memory for current intent and implementation. Read the relevant spec before changing its owning behavior, contract, boundary, source area, or verification flow, and update it with the implementation.

## Spec Map

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Project contract](project.md) | `project.godot`, `scenes/main.tscn`, `tests/check`, `tests/README.md` | Implemented runtime and verification | Changing engine configuration, startup, or checks |
| [Repository structure](repository.md) | `README.md`, directory guides, `.gitignore`, `.gitattributes`, `docs/`, `examples_agents/` | Source ownership, project memory, collaboration boundaries, and provenance | Changing the layout, contribution workflow, or file handling |

## Maintenance

- Keep specs compact, evidence-based, and current.
- Update this map when a spec is added, moved, split, or removed.
- Keep plans, TODOs, work logs, and merge handoffs outside `specs/`.
- Label planned behavior and open decisions; do not present them as implemented facts.
- Date each spec review and identify the implementation commit reviewed, rather than the documentation-only commit that records the review.
