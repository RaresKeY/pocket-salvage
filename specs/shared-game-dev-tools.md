# Shared game-developed tools

Reviewed: 2026-09-29. Implementation: `440e96cca23cb3747b1baeb68813801ace19457b` audio method port.

Canonical owner: `../game-dev-tools`; families: pixel-scaling, audio-synthesis. This project retains its original active entry points as compatibility adapters and its product-specific inputs/configuration. Implementation revision: `440e96cca23cb3747b1baeb68813801ace19457b`. [Consumer manifest](../tools/game-dev-tools.json) pins all 39 required code/schema/resource files by SHA-256 and maps 6 active entry points; [configuration](../tools/game-dev-tools-config.json) preserves source settings.

- `tools/pixel_art/superscale.gd` → `../game-dev-tools/tools/pixel-scaling/src/superscale.gd`
- `scripts/art/pixel_scaling.gd` → `../game-dev-tools/tools/pixel-scaling/src/pixel_scaling.gd`

Python adapters prefer an explicit GAME_DEV_TOOLS_ROOT or sibling checkout and otherwise use the tracked tools/shared/game-dev-tools closure. They expose the original functions and commands. A present checkout with mismatched bytes fails; update it through the reviewed sync procedure instead of bypassing pins. Godot adapters use the tracked bundle and require the manifest checks. No model, game artwork/content, release output or credentials is moved.

Pixel lab/playground scenes and nearest/linear sampling conventions remain local. scripts/art/pixel_scaling.gd preserves its static API by extending the pinned core; superscale.gd verifies all pins before delegation. Run the complete ./tests/check contract after changes.

Change shared method code in the canonical repository, run full original-versus-ported and independent reuse tests, commit it, then explicitly sync this consumer and commit its reviewed adapter/config/pin/spec changes together. Use the project's prescribed managed container runtime; the canonical tool image contains FFmpeg/NumPy/OpenCV/Pillow/jsonschema for generalized CPU jobs. Keep gameplay and final audio/visual/renderer acceptance in this project. Complete revalidation is recorded in the canonical reports/port-verification.json and its specs/verification.md.

## Audio authoring ownership

All four procedural commands delegate to the complete shared effects, wrapped music, filtered rain and wind methods. The complete 26-file collection matches byte for byte; the original rain/wind signal regressions pass against both implementations. Exact expressions, chords, arpeggio, seeds, names, rates and output paths remain in this configuration. `make_sfx.py` retains its rain/wind follow-up generation. Source regeneration retains replacement; independent callers reject existing outputs by default. Runtime playback and current masters stay owned here.

- `tools/audio/make_sfx.py` → `../game-dev-tools/tools/audio-synthesis/src/pocket-salvage/tools/audio/make_sfx.py`
- `tools/audio/make_music.py` → `../game-dev-tools/tools/audio-synthesis/src/pocket-salvage/tools/audio/make_music.py`
- `tools/audio/make_rain.py` → `../game-dev-tools/tools/audio-synthesis/src/pocket-salvage/tools/audio/make_rain.py`
- `tools/audio/make_wind.py` → `../game-dev-tools/tools/audio-synthesis/src/pocket-salvage/tools/audio/make_wind.py`

All active audio adapters were replayed from the complete pinned offline bundle in isolated fixtures with the canonical checkout unavailable. Source output folders were never regenerated. Complete method review, original-versus-shared output parity and independent reuse are recorded in the canonical `specs/audio-synthesis.md` and `reports/audio-synthesis-verification.json`. These are authoring checks; existing full-game and release evidence retains its original scope.

Imported Python adapters execute in their own module globals. Rebinding public settings (`RATE`, `OUT`) or functions preserves original module behavior; explicit unregistered imports and dataclass namespaces are covered by the shared regression suite. The complete 15-test audio suite passes; bootstrap code remains trusted local code, and closure hashes verify consistency before the selected method executes.
