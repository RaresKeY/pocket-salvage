# First playable integration

## User intent

Develop reusable subsystems with independent lab scenes, keep design and implementation specs current, and assemble features incrementally toward a fun game. The user requested subagents, separate worktrees, ongoing commits/pushes, and testing until the result is ready.

The user also requested smooth motion without cable resets or unprompted straightening, reproducible standalone builds for Linux/Web and other supported desktops, and version v0.1.0 visible as small corner text.

## Prototype choices (AI-inferred)

Compose a small timed sorting experiment with six objects and three labeled bins. Keep the reviewed scene arrangement separately accessible; launch the playable lab from that scene. Two minutes allows room to learn the crane. Use keyboard controls with one magnet toggle, visible timer/score/carry status, pause, results and restart.

The first layout places scrap left and bins right, making lifting above the rims and managing swing the central task. Use +100 correct and −25 wrong. Revised 2026-09-25 (Dale, jam polish pass): the score may go negative so an early mistake shows; a wrong bin throws the item back out rather than consuming it, so a round cannot end "all sorted" with nothing sorted; clearing the yard early earns 5 points per remaining second so speed is worth replaying for. Allow every represented material to attach, including rubber, as an arcade convenience. Rectangular collision approximations and mass values are provisional. Tune them through playtests rather than presenting these choices as approved final rules.

Keep independent crane, sorting, HUD and level labs useful as regression/reproduction scenes. Future integration can add bin-front masks, richer level variation, sound and more physical load coupling once the basic handling has been reviewed. Current behavior and limitations are in [the integration spec](../specs/salvage_prototype.md).

## Presentation and sound (Dale, 2026-09-25)

User direction: "improve the background with more sprites and movement, a moon or something and other things to make it exciting, and add lots of nice polish and any other sprites we can add." Delivered as a night scrapyard: animated sky, moon, clouds, skyline, floodlights, beacons, a crow, gull and rat, smoke, plus score popups, landing shake, a hurry timer and synthesised retro sound. The ten new sprites are drawn with Bitwright's `scrapyard` set, matched to the magnet anchor like the first 28. Proposed, awaiting RaresKeY: swappable crane heads (magnet lifts only steel, a gripper for copper and rubber, a head rack at the rail end), and a conveyor that feeds scrap in so rounds escalate.
