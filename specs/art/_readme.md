# Art Specs Map

Reviewed: 2026-09-24. Implementation revision: `2cff8e5`.

This is a nested documentation module, not a Git submodule. It describes rendering and asset-processing contracts; evolving style choices remain in `design/`.

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Sampling and aliasing](sampling.md) | `project.godot`, asset import settings, `labs/pixel_scaling/preview.gd` | Pixel versus smooth art, 3D materials, filtering, integer scale, and alpha | Importing or displaying any art |
| [Superscaling and lab](pixel_scaling.md) | `scripts/art/pixel_scaling.gd`, `tools/superscale`, `tools/pixel_art/`, `labs/pixel_scaling/`, `tests/` | Exact replication tool, lineage, comparison UI, and verification | Enlarging sprites or changing the lab |
| [Enlarged sprite playground](sprite_playground.md) | `assets/bitwright_8x/`, `labs/sprite_playground/` | 8× art copies, runtime filtering and mouse-grab physics fixture | Changing enlarged art or sprite interaction |
