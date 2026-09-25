# Yard layout experiments

## User design

Develop independently reusable subsystems in focused lab scenes, document intent in design and implementation in specs, and assemble proven pieces incrementally toward a fun crane sorting game. Use enlarged 8× copies of contributed pixel art, scaled down at runtime. The user authorized parallel worktrees and implementation/testing of the next labs. Existing direction defers final concrete object geometry; diagnostic lab shapes are not selected gameplay design.

2026-09-25 ([jam polish](../prompts/source/jam-polish.md)), Dale: items could get stuck between the bins; scrap should start as a big pile rather than placed in a row; the background should gain more sprites and movement, a moon, and other things to make it exciting; seagulls repeated too often and should sometimes land.

## AI-inferred design

A small deterministic layout factory separates object placement data from rendering and physics ownership. Two arrangements can expose assumptions about material order without duplicating crane, round or collision implementations. Rectangular physical extents and material/mass assignments are provisional caller input, not art-derived geometry or approved object design.

Pile (Claude, 2026-09-25, from Dale's "big pile"): ten pieces, five steel, three copper and two rubber, stacked in rows of 4, 3, 2 and 1 with a small fixed jitter so physics tumbles them into a heap at the start. The mix gives each head real work and uses more of the scrap sprites. Spawn rectangles never overlap, which the level test enforces.

Bins (Claude, 2026-09-25, from Dale's bug report): the earlier 50-unit gaps between bins were narrower than the magnet, so scrap wedged there could not be fetched. Bins now sit shoulder to shoulder sharing one wall. Two tool stands sit at the left end, beside the pile.

Scenery (Claude, 2026-09-25, approved by Dale with "yes do it all"): a night yard. A banded sky that meets the skyline tile's own colour, seeded twinkling stars, a moon with a soft glow, drifting clouds, a scrapyard skyline standing on the fence, one dimmed junk heap in the corner away from anything the player picks up, two floodlights with flickering light cones, blinking beacons on the tower tops, a crow on the fence, an occasional rat, and smoke from the heap. Scenery keeps moving on the start, pause and results screens and never collides with play.

Gulls (Claude, 2026-09-25, from Dale's feedback): each gull flies at its own speed and flap rate, rises and dips, and sometimes glides; one to three arrive every 10 to 24 seconds, at most three at once; about half land on a free perch (floodlight tops, four rail spots, the heap, two fence spots), look around for 7 to 18 seconds and leave, and a perched gull takes off when the trolley or head comes within 90 units.

Open questions: whether layout variation adds enjoyment, and whether scenery ever competes with the scrap for attention. Current source contracts and validation live in [the implementation spec](../specs/level_layout.md).

## Level progression, 2026-09-25

User design: RaresKeY asks to follow Dale’s pile spawning with fewer pieces at the start and more in later levels ([exact request](../prompts/source/level-flow.md)).

AI-inferred design: the shared layout accepts 4/6/10/12-piece pile recipes. Existing ten-piece lab fixtures remain the default; playable count comes from the level catalog. Pieces retain gaps, jitter, bounds, materials and physical settling.
