# Mask and collision-parts fixture

Open `labs/physics/lab.tscn` and run that scene (F6). Use `./labs/capture physics` for automated off-desktop Gamescope/GPU validation through the managed runner.

The left sample uses the contributor's `bin_steel_mask.png` to hide parts of a procedural striped texture. A faint amber underlay makes the cutout visible. It demonstrates mask placement without building a gameplay bin. The right probe moves through a non-solid amber sensor and bounces against a solid mint boundary. The visual mask, solid and sensor each have independent toggles and status text; pause freezes the probe.

These rectangles and probe exist **only in this lab**. No object dimensions, box assignments, magnet pull region or gameplay collision taxonomy are supplied by the reusable module. No automatic physics silhouette is generated from the mask.

Captures verify actual rendered alpha with the mask enabled, disabled and translated, plus a solid contact and a sensor entry. `./tests/check` separately verifies collision filtering, resource ownership, independent enabling, material restoration and lab startup. Tests use synthetic shapes, not final game objects.
