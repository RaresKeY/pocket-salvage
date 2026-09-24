# Sampling and Aliasing

Reviewed: 2026-09-24. Implementation revision: `2cff8e5`.

## Art classification

Classify each asset by intended appearance before importing it. Record exceptions with the owning art/subsystem spec.

| Asset class | Sampling and import convention | Display convention |
|---|---|---|
| Pixel sprites and pixel UI | Lossless import, nearest filtering, no mipmaps for magnified 2D art, repeat disabled unless deliberately tiled | Integer scale and aligned final screen positions; preserve aspect ratio |
| Smooth illustrations and painted UI | Lossless masters; linear filtering for smooth scaling, with mipmaps considered when minification needs them | Preserve aspect ratio; fractional layout is allowed |
| Fonts and vector UI | Retain the font/vector rendering pipeline; ordinary text keeps its normal antialiasing | Do not bake text into enlarged sprite pixels merely to follow the sprite rule |
| 3D material textures | Select the material's sampler independently; use mipmaps and appropriate filtering for receding surfaces, or document an intentional pixel treatment | Test at actual camera distances, angles, and motion; nearest 2D scaling does not solve 3D aliasing |

## Implemented defaults and lab exceptions

`project.godot` sets the default CanvasItem texture filter to nearest (`0`), repeat to disabled (`0`), and 2D MSAA to disabled (`0`). Smooth-art nodes can explicitly override the CanvasItem filter. No 3D AA or mipmap policy is globally disabled. The calibration PNG is imported losslessly with no mipmaps.

The lab renders at native window resolution with no root stretch. Integer and baked previews align their drawing positions to screen pixels; fractional panels deliberately use half-step scales, and the linear comparison explicitly overrides the nearest default. Font antialiasing remains intact.

The lab loads decoded source PNGs directly, before importer processing, to isolate scaling behavior. It is a developer lab for the source checkout; no exported-game packaging of raw comparison files is implemented.

Visual occlusion masks in the [object subsystem](../physics.md) use alpha-only coverage, nearest filtering and repeat disabled. Their transforms are independent from physical shapes. The diagnostic physics fixture fits its whole world fractionally when needed; this is a lab exception, not the selected gameplay pixel viewport.

## Pixel-art contract for future gameplay

Choose an authored base resolution with the game's design. A low-resolution pixel-art world should use an integer-scaled viewport and preserved aspect ratio, accepting unused screen margins rather than fractional stretching. A 3D world with pixel UI may instead isolate that UI in its own integer-scaled layer. This gameplay viewport setup is a convention to apply when gameplay exists, not a setting already selected by this lab.

Keep pixel sprites and cameras aligned at the final display stage. Arbitrary rotation, subpixel camera movement, non-integer rescaling, and minification can still change apparent pixel shapes. Enlarging a file first does not prevent those artifacts. Do not enable both transform and vertex snapping indiscriminately.

Preserve transparent source pixels during exact processing. Runtime alpha-edge repair or premultiplication is a separate import decision; evaluate halos on light, dark, and checker backgrounds. Do not claim byte preservation for processed import data without testing it.

## References and verification

Godot's [resolution guide](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) explains integer stretch and unused screen margins. [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html) documents sampling, snapping, and MSAA boundaries. These references inform the convention; the local Godot 4.7 runtime and the lab checks establish the implemented behavior.

Use the calibration chart and actual assets in the lab. Inspect opaque edges, one-pixel lines, alpha transitions, and motion at integer and fractional scales. Headless startup establishes no visual quality or hardware-renderer result.
