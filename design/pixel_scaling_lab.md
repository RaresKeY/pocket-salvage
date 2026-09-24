# Pixel Scaling Experiment

## User design

The user requested a tool for enlarging pixel art, art-level aliasing conventions under specs, and a lab to test and showcase scaling. The motivating example is a source pixel becoming a 10×10 block. Contributor art will live beneath `assets/`. See [the source directive](../prompts/source/pixel-scaling.md).

## AI-inferred design

Use exact integer nearest-neighbor replication, preserving decoded colors and transparency rather than synthesizing detail. Compare native integer rendering, fractional nearest sampling, fractional linear sampling, and a baked enlargement in one lab. Keep the lab's UI at native screen resolution so it does not introduce another fractional stretch.

The lab has a neutral dark background, mint emphasis, readable native-resolution text, and visible transparency checkers. This is a technical comparison surface, not the game's selected art direction. A deterministic calibration image supplies one-pixel checks, a diagonal, thin lines, and an alpha ramp until contributor art arrives.

Open the lab as the temporary project entry point. Preserve the empty gameplay scene for the later MVP. Assets are selected from the project, with a refresh control, integer scale, optional motion comparison, and a ready-to-copy export command. Large images stay at the displayed scale inside scrollable previews.

The game-wide art contract distinguishes crisp pixel art from smooth painted art and 3D textures; one global filtering rule is not sufficient for every asset type. Actual gameplay viewport resolution remains undecided.

## User extension: enlarged runtime assets

The user requested enlarged copies in a new folder, then a scene displaying them with one physics-enabled, grabbable object. The user explicitly selected **8×**. The large texture remains in memory and is scaled down with runtime filtering.

## AI-inferred playground details

Use the existing Bitwright sprites and masks, a gallery, and a washing machine with a spring-based mouse grab. Expose display size and linear/nearest filtering; Q/E turns the grabbed object. The rectangular collision approximation is a lab fixture, not final gameplay geometry. Current behavior lives in [the playground spec](../specs/art/sprite_playground.md).
