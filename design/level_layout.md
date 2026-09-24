# Yard layout experiments

## User design

Develop independently reusable subsystems in focused lab scenes, document intent in design and implementation in specs, and assemble proven pieces incrementally toward a fun crane sorting game. Use enlarged 8× copies of contributed pixel art, scaled down at runtime. The user authorized parallel worktrees and implementation/testing of the next labs. Existing direction defers final concrete object geometry; diagnostic lab shapes are not selected gameplay design.

## AI-inferred design

A small deterministic layout factory separates object placement data from rendering and physics ownership. Two arrangements can expose assumptions about material order without duplicating crane, round or collision implementations. Six pieces leave visible gaps in the pickup area, and three separated bins offer an initial sorting experiment. Rectangular physical extents and material/mass assignments are provisional caller input, not art-derived geometry or approved object design.

The static lab proves configuration and display only. A combined playtest should establish whether the crane can retrieve every piece, clear each rim and recover mistakes before these placements become a game level. Open questions include crane travel limits, acceptable sorting difficulty, believable magnetic pickup of rubber-labelled fixtures, mixed-material classification, and whether layout variation adds enjoyment. Current source contracts and validation live in [the implementation spec](../specs/level_layout.md).
