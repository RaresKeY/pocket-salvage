# Scene Composition

Godot scenes own composition and node relationships. `main.tscn` is the startup scene: a static scrapyard composition using 8× copies of the teammate’s sprites at their original world sizes. Named groups under `Stage/Viewport/Yard` keep the environment, gantry, incoming scrap, crane, bins and loose scrap editable in Godot. `Presentation/HUD` contains native-resolution labels and the supplied coin/timer icons. Read [the scene spec](../specs/scene_preview.md) for scaling and scope. The [pixel-scaling lab](../labs/pixel_scaling/README.md) remains separately runnable.

Keep runtime logic in `scripts/`, media in `assets/`, structured content in `data/`, and current subsystem contracts in `specs/` as behavior is added.

Wheel zooms smoothly toward the pointer; left or middle drag pans; F resets the view. The scene uses linear sampling of the enlarged textures at window resolution.
