# First playable integration

## User intent

Develop reusable subsystems with independent lab scenes, keep design and implementation specs current, and assemble features incrementally toward a fun game. The user requested subagents, separate worktrees, ongoing commits/pushes, and testing until the result is ready.

## Prototype choices (AI-inferred)

Compose a small timed sorting experiment with six objects and three labeled bins. Keep the reviewed scene arrangement separately accessible; launch the playable lab from that scene. Two minutes allows room to learn the crane. Use keyboard controls with one magnet toggle, visible timer/score/carry status, pause, results and restart.

The first layout places scrap left and bins right, making lifting above the rims and managing swing the central task. Use +100 correct and −25 wrong, clamped to zero. Allow every represented material to attach, including rubber, as an arcade convenience. Rectangular collision approximations and mass values are provisional. Tune them through playtests rather than presenting these choices as approved final rules.

Keep independent crane, sorting, HUD and level labs useful as regression/reproduction scenes. Future integration can add bin-front masks, richer level variation, sound and more physical load coupling once the basic handling has been reviewed. Current behavior and limitations are in [the integration spec](../specs/salvage_prototype.md).
