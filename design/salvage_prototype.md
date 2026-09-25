# First playable integration

## User intent

Develop reusable subsystems with independent lab scenes, keep design and implementation specs current, and assemble features incrementally toward a fun game. The user requested subagents, separate worktrees, ongoing commits/pushes, and testing until the result is ready.

The user also requested smooth motion without cable resets or unprompted straightening, reproducible standalone builds for Linux/Web and other supported desktops, and version v0.1.0 visible as small corner text.

2026-09-25 ([jam polish](../prompts/source/jam-polish.md)): RaresKeY asked Dale to treat the repository as the jam entry and move it towards polish. Dale approved the AI's rule fixes and art pass ("yess") and its scenery and feedback list ("yes do it all"), reported scrap stuck between bins, and asked for swappable heads, a big pile, crane noise, subtle music, a claw that closes only on the item, livelier gulls, and DRY reusable code. RaresKeY then asked that design and specs stay current, with human instruction kept apart from AI inference.

## Prototype choices (AI-inferred)

Compose a small timed sorting round: scrap on the left, three labeled bins on the right, the scene arrangement still reachable separately. Keyboard controls with one grip toggle, visible timer/score/carry status, pause, results and restart. The central task is lifting above the rims and managing swing.

Current round (Claude, 2026-09-25, from the directions above): ten pieces in a tumbling pile, magnet and claw heads swapped at two tool stands, a 240-second round, +100 correct, 25 off for a wrong bin with the item thrown back into play, 5 points per second left for clearing the yard. The reasoning and numbers live in [crane](crane.md), [sorting and rounds](round.md), [level layouts](level_layout.md), [round HUD](round_hud.md) and [audio](audio.md). Rectangular collision approximations and masses stay provisional and are tuned through playtests, not presented as approved final rules.

Feedback polish (Claude, approved in "yes do it all"): sparks on pickup and on a correct sort, dust where scrap lands hard, floating score numbers, a small stage shake when heavy scrap lands, and a pulsing timer in the last 10 seconds.

Keep independent crane, sorting, HUD and level labs useful as regression and reproduction scenes. Future integration can add bin-front masks, richer level variation and more physical load coupling once handling has been reviewed. Current behavior and limitations are in [the integration spec](../specs/salvage_prototype.md).
