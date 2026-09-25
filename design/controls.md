# Player controls

## User design

RaresKeY, 2026-09-25: [exact words](../prompts/source/controller-mobile.md). Rename and fix the workspace folder; add explicit controller support; detect mobile players in the Web build and provide an on-screen controller at the bottom right.

## AI-inferred design

Keep the existing game rules and dark/mint HUD. Share movement and command routing across devices instead of implementing a separate mobile game. Standard controller layout: left stick/D-pad moves and reels; A/south is primary or grip, X/west swaps heads, Y/north restarts, Start is contextual start/pause/resume/replay, B/east pauses/resumes, bumpers toggle music/SFX. Use a 0.2 stick deadzone and preserve proportional movement. Hints follow the last input family.

Use a multi-touch D-pad and labeled Grip/Swap buttons in the bottom-right footer, each at least 44×44 CSS pixels. Keep start/pause/audio controls in the existing HUD. Detect Web Android/iOS, including iPadOS desktop-site identification; do not show the pad merely because a desktop viewport is narrow. `--touch-controls` is a diagnostic override.

Wrap the header on narrow viewports, bound the modal to screen width, and stack footer text above the right-aligned controller below 600 logical pixels. Preserve the entire yard’s aspect ratio; landscape gives phones more usable yard width. Scale mobile Web UI against canvas CSS width to preserve target size across pixel densities.

Cancel touch ownership on pause, focus loss, restart, rotation and results. Dragging off a direction releases it; multiple fingers can independently move, reel and grip. Disconnecting the active controller pauses the round, and physical movement must return to neutral after interruption. Preserve keyboard shortcuts and mouse controls. Version the playable update as v0.1.4 and use the existing tag delivery workflow to update downloads and Pages.

On touch landscape screens shorter than 540 logical pixels, the controller occupies a separate bottom-right panel and the yard/footer reserve a right-side column. The redundant touch hints are hidden there to give the yard more height. Portrait and taller layouts keep the controller in the footer. This follows the same theme and leaves game rules unchanged.
