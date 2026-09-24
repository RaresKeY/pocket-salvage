# Art Specs Map

Reviewed: 2026-09-24. The prior implementation baseline is `08eed65`; the pixel-scaling implementation is under review.

This is a nested documentation module, not a Git submodule. It describes rendering and asset-processing contracts; evolving style choices remain in `design/`.

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Sampling and aliasing](sampling.md) | `project.godot`, asset import settings, `labs/pixel_scaling/preview.gd` | Pixel versus smooth art, 3D materials, filtering, integer scale, and alpha | Importing or displaying any art |
| [Superscaling and lab](pixel_scaling.md) | `scripts/art/pixel_scaling.gd`, `tools/superscale`, `tools/pixel_art/`, `labs/pixel_scaling/`, `tests/` | Exact replication tool, lineage, comparison UI, and verification | Enlarging sprites or changing the lab |
