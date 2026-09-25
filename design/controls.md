# Player controls

## User design

RaresKeY, 2026-09-25: [exact words](../prompts/source/controller-mobile.md). Rename and fix the workspace folder; add explicit controller support; detect mobile players in the Web build and provide an on-screen controller at the bottom right.

RaresKeY, 2026-09-25: [remove the legacy F2 preview switch](../prompts/source/remove-preview-shortcut.md) from the launcher/game.

RaresKeY, 2026-09-25: [exact mobile overlay request](../prompts/source/mobile-overlay.md) supersedes the original arrow-grid placement: proportional right stick, diagonal left action buttons, smooth icons, Linux preview and browser fullscreen.

## AI-inferred design

Keep the existing game rules and dark/mint HUD. Share movement and command routing across devices instead of implementing a separate mobile game. Standard controller layout: left stick/D-pad moves and reels; A/south is primary or grip, X/west swaps heads, Y/north restarts, Start is contextual start/pause/resume/replay, B/east pauses/resumes, bumpers toggle music/SFX. Use a 0.2 stick deadzone and preserve proportional movement. Hints follow the last input family.

Use a rounded screen-space right analog stick and diagonal left action circles, with smooth pale-gray generated Grip/Swap icons. Infer a 56px stick radius, 60px action circles and 22–26px edge clearance. Input displacement sets proportional speed; only physical sticks have a 20% radial deadzone. Keyboard/D-pad directions retain maximum per-axis speeds. Strongest input wins per axis so devices cannot add speed. Preserve pause/focus/restart/rotation cancellation and neutral gating.

Keep the square pixel HUD, move touch feedback to its header, and let the aspect-preserved yard extend beneath controls without reserving a column/footer. The Linux preview defaults to 844×390 and supports mouse dragging. Web fullscreen uses a DOM user gesture with standard/prefixed capability detection and a browser-menu/Home-Screen fallback message. This does not promise fullscreen on browsers that disallow it.

Remove the F2 mapping, scene-switch command and HUD navigation hint entirely. `play.sh` already opens the configured game and inherits this removal. Preserve the independently openable scene-preview asset/lab and its camera tests; it is not reachable from gameplay.
