# Calibration Media

`calibration.png` is a 32×32 diagnostic fixture with one-pixel checkers, a diagonal, thin lines, and an alpha ramp. It is generated deterministically by `tools/pixel_art/make_fixture.gd` from project-owned code. No external art, AI image-generation call, or third-party license is involved.

Its `.import` settings use lossless storage with no mipmaps. The lab loads the source PNG directly; it preserves decoded pixel values independently of Godot's import processing. This fixture is not an approved game-art direction. Contributor art may be added in separate folders beneath `assets/`.
