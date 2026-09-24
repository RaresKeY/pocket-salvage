# Superscaling and Comparison Lab

Reviewed: 2026-09-24. Implementation revision: `2cff8e5`.

## Tool contract

`tools/superscale` orchestrates the shared managed Godot runner. `tools/pixel_art/superscale.gd` is the portable Godot CLI; `scripts/art/pixel_scaling.gd` calls native `Image.resize` with nearest interpolation. No additional Python imaging dependency or AI image model is used.

Input and output are project-relative PNG paths. The factor is an integer from 1 through 32. Each decoded source pixel becomes an equal factor-by-factor block. Output is RGBA8, at most 16 megapixels and 16,384 pixels on either edge. PNG header dimensions are checked before decoding; 16-bit PNGs are rejected rather than silently losing precision. Input images and existing outputs are never replaced.

The tool writes an enlarged PNG and an adjacent `.png.json` provenance record containing relative paths, source/output SHA-256, dimensions, factor, algorithm, output format, and engine version. It refuses to run if either destination already exists. Failure to write provenance removes the new output. This is exact pixel replication, not invented detail; a 10× scale uses 100× as many output pixels.

The numerical contract is preservation of decoded RGBA values, not preservation of original PNG compression, metadata, or color-profile chunks. Keep the original file as the master. Typical sprites can be enlarged at runtime with nearest sampling instead of storing larger source files.

## Lab contract

`labs/pixel_scaling/lab.tscn` is the current project entry point. It recursively lists PNGs beneath `assets/` and provides refresh, scale, optional motion, and a copyable tool command. It displays native integer-nearest, fractional-nearest, fractional-linear, and in-memory baked-nearest previews. Fractional views use the chosen factor plus 0.5; the baked result is displayed 1:1. Oversized requested results show an error and clear stale previews.

The responsive grid uses four columns at widths of at least 1700, two from 1000, and one below 1000. The page and individual previews scroll when necessary; they do not silently fit or distort the displayed image. Motion is optional and stops processing when disabled. Source files are loaded directly so import preprocessing does not hide the sampling comparison.

`assets/pixel_lab/calibration.png` is a reproducible diagnostic chart authored by `tools/pixel_art/make_fixture.gd`, not selected game art. It tests checkers, a diagonal, one-pixel lines, and transparency. `scenes/main.tscn` remains the empty future-game placeholder.

## Verification

`tests/pixel_scaling_test.gd` verifies exact blocks at 1×, 2×, and 10×, transparent/partial alpha, PNG round-trip, source immutability, and size/factor guards. `tests/test_superscale_cli.py` exercises the actual CLI, provenance hashes, refusal to overwrite, missing input, invalid factors/options, 16-bit rejection, and oversized PNG headers. `tests/run_checks.py` bounds each process and treats script errors or missing success markers as failures. The lab's self-test exercises asset selection, scale updates, baked size, motion, refresh, keyboard focus traversal, and mouse-toggle input through Godot's viewport.

`labs/pixel_scaling/capture` uses background Gamescope with the shared hardware-enabled runner, under one project lock. It captures 1920×1080, 1280×720, 960×540, and 854×480 by default, preserving logs and image/renderer metadata under ignored `artifacts/generated/pixel_scaling/`. When both complete images are visible, the captured integer and baked regions must match byte-for-byte. Offscreen comparisons are explicitly reported as unchecked. This capture is local verification, not a public build.

No controller interaction, arbitrary 3D-material case, or exported-game comparison is claimed by these checks. Native GPU captures and headless control/input checks cover the stated paths; contributor art still needs inspection when it arrives.

The **Sprite playground** button opens [the enlarged-art physics scene](sprite_playground.md), which renders stored 8× textures at smaller sizes.
