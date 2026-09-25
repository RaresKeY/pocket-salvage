# Art Specs Map

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`.

This is a nested documentation module, not a Git submodule. It describes rendering and asset-processing contracts; evolving style choices remain in `design/`.

| Spec | Owning sources | Scope | Read when |
|---|---|---|---|
| [Sampling and aliasing](sampling.md) | `project.godot`, asset import settings, `labs/pixel_scaling/preview.gd` | Pixel versus smooth art, 3D materials, filtering, integer scale, and alpha | Importing or displaying any art |
| [Superscaling and lab](pixel_scaling.md) | `scripts/art/pixel_scaling.gd`, `tools/superscale`, `tools/pixel_art/`, `labs/pixel_scaling/`, `tests/` | Exact replication tool, lineage, comparison UI, and verification | Enlarging sprites or changing the lab |
| [Enlarged sprite playground](sprite_playground.md) | `assets/bitwright_8x/`, `labs/sprite_playground/`, `tools/pixel_art/import_bitwright.py` | 8× art copies (117 files, 41 gallery tiles), Bitwright import, runtime filtering and mouse-grab physics fixture | Changing enlarged art or sprite interaction |

## Shared yard drawing

`scripts/art/yard_art.gd` is the one rule for drawing 8× art in the yard: `DIR`, `FACTOR` (8), `path(name)`, `exists(name)`, `texture(name)`, `world_size(texture, art_scale)`, `fit(node, art_scale)` (scale `art_scale / 8` with linear filtering) and `sprite(name, art_scale, at)`. Literal `preload` paths stay where Godot requires constants. `scripts/fx/burst_2d.gd` is a self-freeing one-shot AnimatedSprite2D built from numbered frames (`<prefix>_01.png` onward, counted by `frame_numbers`); its static `add_frames` also builds the heads', gulls' and ambience animations, and `frames_for` caches SpriteFrames per prefix.
