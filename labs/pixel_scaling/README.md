# Pixel Scaling Lab

Open `project.godot` in Godot 4.7, open `labs/pixel_scaling/lab.tscn`, and run the current scene (F6) to see the lab. Add contributor PNGs anywhere beneath `assets/`, then select **Refresh art**. Select an image, choose an integer factor, and compare the four sampling modes. **Motion test** shows snapped versus subpixel movement. Scroll large previews without changing their scale.

The supplied 32×32 chart is diagnostic media, not a game-art proposal. At 10×, each source pixel becomes a 10×10 block. Fractional views intentionally use 10.5×; the baked 320×320 image is shown at 1× for comparison with native 10× sampling.

From the project root on the shared workstation:

```sh
./tools/superscale --input assets/pixel_lab/calibration.png --factor 10 --output artifacts/generated/calibration-10x.png
./tests/check
./labs/pixel_scaling/capture
```

The first command writes a PNG and provenance without replacing existing files. The capture command stays off the desktop, uses hardware rendering, and saves its resolution matrix under `artifacts/generated/pixel_scaling/`. Set `GODOT_PODMAN_RUNNER` when the shared runner is not in a sibling checkout.

For a machine with local Godot 4.7, subject to its local execution rules, the portable tool command is:

```sh
godot --headless --path . --script tools/pixel_art/superscale.gd -- --input assets/pixel_lab/calibration.png --factor 10 --output artifacts/generated/calibration-10x.png
```

Read [the art specs](../../specs/art/_readme.md) before changing filtering, scaling, or import conventions. The lab uses raw project PNGs and is not packaged as a public export.
