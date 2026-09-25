# Creation Tools

Reserve this directory for one-shot utilities that create or transform project material. Tools are not shipped runtime logic and are not the test suite. Document each tool's input, output, dependencies, repeatability, and provenance alongside it when added.

Prototype and orchestrate in Python; use native code for measured bottlenecks. Follow local execution boundaries. Generated output belongs in its owning source area or an appropriate ignored artifact bucket.

[superscale](superscale) enlarges pixel PNGs through the shared Godot runner; [pixel_art/](pixel_art/README.md) owns the portable CLI and diagnostic-image construction. Verification lives in [tests/check](../tests/check); interactive comparisons live in [labs/](../labs/README.md).

[build/build_all.py](build/build_all.py) exports the standalone prototype from clean source; `build/publish_release.py` validates tags, publishes verified release assets and updates the generated Pages branch; [build contract](../specs/builds.md).

[audio/make_sfx.py](audio/make_sfx.py) synthesises the round's retro sound effects into `assets/audio/` as 16-bit mono WAVs, standard library only and seeded, so rerunning it reproduces the files exactly. Edit a recipe and rerun to change a sound. [audio/make_music.py](audio/make_music.py) writes the 32-second background loop the same way, reusing the effect generator's tone and WAV helpers.
