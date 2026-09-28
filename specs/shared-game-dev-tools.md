# Shared game-developed tools

Canonical owner: `../game-dev-tools`; families: pixel-scaling. This project retains its original entry points as compatibility adapters and its product-specific inputs/configuration. Implementation revision: `4df024008b256e9ded54d254f2225464b40882ba`. [Consumer manifest](../tools/game-dev-tools.json) pins every required code/schema file by SHA-256; [configuration](../tools/game-dev-tools-config.json) preserves source settings.

- `tools/pixel_art/superscale.gd` → `../game-dev-tools/tools/pixel-scaling/src/superscale.gd`
- `scripts/art/pixel_scaling.gd` → `../game-dev-tools/tools/pixel-scaling/src/pixel_scaling.gd`

Python adapters prefer an explicit GAME_DEV_TOOLS_ROOT or sibling checkout and otherwise use the tracked tools/shared/game-dev-tools closure. They expose the original functions and commands. A present checkout with mismatched bytes fails; update it through the reviewed sync procedure instead of bypassing pins. Godot adapters use the tracked bundle and require the manifest checks. No model, game artwork/content, release output or credentials is moved.

Pixel lab/playground scenes and nearest/linear sampling conventions remain local. scripts/art/pixel_scaling.gd preserves its static API by extending the pinned core; superscale.gd verifies all pins before delegation. Run the complete ./tests/check contract after changes.

Change shared method code in the canonical repository, run full original-versus-ported and independent reuse tests, commit it, then explicitly sync this consumer and commit its reviewed adapter/config/pin/spec changes together. Use the project's prescribed managed container runtime; the canonical tool image contains FFmpeg/NumPy/OpenCV/Pillow/jsonschema for generalized CPU jobs. Keep gameplay and final audio/visual/renderer acceptance in this project. Complete revalidation is recorded in the canonical reports/port-verification.json and its specs/verification.md.
