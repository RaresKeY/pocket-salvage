# Development Labs

[Pixel scaling](pixel_scaling/README.md) is the first runnable experiment and currently opens when the project starts. Labs isolate technical comparisons and showcases from the eventual game loop. Keep their intent in `design/` and current behavior in focused specs.

[Rope](rope/README.md) showcases Pocket Salvage's reusable slack, tension, terrain-contact and curve-rendering component. Run the scene directly or use `./labs/capture rope` for off-desktop GPU evidence.

[Mask and collision parts](physics/README.md) demonstrates independent visual masks, caller-authored solids and sensors. Its shapes are disposable fixtures, not game objects. Use `./labs/capture physics` for GPU pixel and contact checks.

[Sprite playground](sprite_playground/README.md) displays the 8× Bitwright derivatives at smaller runtime sizes, with a grabbable physics sprite.

Subsystem proving scenes: `crane/lab.tscn`, `sorting/lab.tscn`, `hud/lab.tscn`, and `level/main.tscn`. Each has focused design/spec documentation and independent tests.

[Playable salvage integration](salvage/README.md) composes these modules into a two-minute round; launch from the main scene’s Play prototype button.
