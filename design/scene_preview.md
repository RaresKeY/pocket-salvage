# Scrapyard Arrangement

## User design

The user requested adding the teammate’s assets to the main scene, arranging them, and opening the scene for inspection. Work must use a separate worktree and must not be pushed yet. The supplied art is Dale Mooney’s Bitwright scrapyard pack already present under `assets/bitwright/`.

## AI-inferred design

Present one side-on yard: a conveyor and incoming scrap on the left, a gantry spanning the work area, a suspended magnet holding a cog, and copper/rubber/steel bins on the right. Arrange the remaining scrap across the foreground to expose all thirteen contributed object types. Keep the backdrop quieter than the crane and sorting targets.

Preserve the provisional 384×216 world-unit composition and native-resolution labels while rendering enlarged textures directly at window resolution. A small title, static coin/timer display, and artist credit frame the composition. Keep the scene static for this review; motion, collisions, sorting, and round rules belong to subsequent gameplay work. The technical labs remain available as separate scenes.

This composition is an AI proposal for review, not user approval of final scene layout, material rules, or visual direction. Current implementation lives in [the scene spec](../specs/scene_preview.md).

## User extension: inspection camera and enlarged art

The user requested smooth mouse-wheel zoom, mouse-drag panning, and use of the big assets specifically in the other AI’s scene in `random-game-scene-preview`. The selected enlargement from the preceding asset task is 8×.

Implementation choices: pointer-anchored exponential zoom, left/middle drag, F to reset, linear texture filtering, and a fixed HUD. Keep the existing arrangement and static gameplay scope.
