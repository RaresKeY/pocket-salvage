# Bitwright art at 8×

These 117 accepted PNG derivatives replicate each original pixel as an 8×8 block with nearest-neighbor scaling. Originals remain in `../bitwright/`. Masks receive the same multiplier to preserve alignment. Adjacent `.png.json` records contain source/output hashes, dimensions, factor and engine provenance.

These are project art assets requested for runtime use, not release outputs. Regenerate into an empty destination using `tools/superscale --input assets/bitwright/NAME.png --factor 8 --output assets/bitwright_8x/NAME.png`; the tool refuses overwrites. No generated detail or smoothing is baked into the files.

The [sprite playground](../../labs/sprite_playground/README.md) loads these textures and draws them smaller with selectable linear/nearest sampling. An object displayed at twice its original dimensions uses a sprite scale of `2 / 8 = 0.25`. Arbitrary rotation and filtered scaling intentionally resample the screen image; the stored pixels remain exact.

The [scene preview](../../specs/scene_preview.md) also uses these textures, with linear sampling and smooth camera zoom.
