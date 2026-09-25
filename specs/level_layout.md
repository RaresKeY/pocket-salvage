# Prototype yard layout subsystem

Reviewed: 2026-09-25. Implementation: level-flow change based on `575407c`.

## Layout data

`scripts/level/yard_layout.gd` is a RefCounted data factory. `create_layout(variant: int = 0, scrap_count: int = 10) -> Dictionary` returns fresh caller-owned data; variants wrap modulo two. Keys: `bounds` `Rect2(0, 0, 1200, 480)`, `ground_top` 440, `art_scale` 1.6 (world units per source pixel), `crane_anchor` `(200, 45)`, `pickup_bounds` `Rect2(150, 240, 270, 200)`, `tool_stand` `(96, 424)`, `variant`, `scrap` and `bins`.

`scrap` holds ten dictionaries (five steel, three copper, two rubber) with unique integer `id`, StringName `material`, 8× `texture` path, centre `position`, rectangle `size` and positive `mass`. Rows are `[3,1]`, `[3,2,1]`, `[4,3,2,1]` or `[4,4,4]` respectively; pieces are stacked around x285 with 8-unit gaps and a fixed jitter under half the gap, so none start overlapping and physics tumbles them into a heap. Variant 1 rotates the order by five. `bins` holds three dictionaries with material, centre, size 150×100 and texture, centred at x650/792/934, y390, spaced `150 - SortingBin.WALL` so neighbours share a wall. No random generator or shared mutable state is involved.

These dimensions, masses and materials are prototype fixtures, not approved objects or art-derived geometry. The caller builds any collision, sensor or gameplay object. No physics, scoring or timer is owned here.

## Backdrop

`scripts/level/yard_backdrop.gd` draws the static yard from 8× art with linear sampling: optional sky fill (`draw_sky`), the fence tiled along the floor, the `backdrop_skyline_tile` standing on the fence tile's opaque top sky rows (`FENCE_SKY_ROWS` 10), a dimmed `backdrop_junk_heap` at x1080 clear of pickup and bins, lattice towers at both ends (cap and foot once, one 4-pixel period repeated), then floor and rail. Textures are held on the node, since a texture loaded inside `_draw` is freed when it returns and renders white. Sizes come from `YardArt.world_size`.

## Ambience

`scripts/level/yard_ambience.gd` is the salvage round's animated scenery, with `PROCESS_MODE_ALWAYS`, no collision, and any absent sprite skipped. The `far` layer (z −11) draws a banded gradient from `0c0a18` to the skyline tile's top colour `181222`, 70 seeded twinkling stars, the moon with a glow and four drifting clouds. The `near` layer (z −4) holds two floodlights at x62 and x1138 with flickering light cones, blinking tower beacons, a crow hopping along the fence between x460 and 560, a rat crossing the floor every 18 to 30 s, smoke rising from the heap, and gulls. `crane_points` is a caller Callable returning moving crane positions.

Gulls (`scripts/level/yard_gull.gd`) arrive every 10 to 24 s, alone or in a loose group of two or three, at most `MAX_GULLS` (3) alive. Each flies with its own speed and flap rate, rises and dips, and glides with wings held. 55% claim a free perch: the two floodlight tops, rail points x260/520/780/1000, the heap top and the fence rail at x300 and x1110. A gull glides down, perches with the `critter_gull_perched` frames for 7 to 18 s turning now and then, and takes off early if a crane point comes within `SCARE_DISTANCE` (90). Perches free when a gull leaves or is removed.

## Labs and verification

`labs/level/main.tscn` shows the data without physics and switches variants with a button or Tab. `tests/level_test.gd` checks deterministic independent data, spawn separation and bounds, masses, unique IDs, all materials present, bins sharing walls and floor alignment, resources, and 29 staged lab nodes per variant. `tests/ambience_test.gd` checks nine perches, landing on a perch, staying put, a crane scare, leaving and freeing itself, a crossing gull that rises and dips then leaves, and the spawn cap with perches released. None of this is a reachability or fun claim.

`yard_ambience.gd` exposes `wind` (set by the weather wind effect); clouds drift at their base speed plus `wind x 0.15` and wrap at either edge.

Blood Moon ambience is configured by an optional flag before construction. It changes sky/moon/cloud/light colors and suppresses gulls/rats. Round-owned generator state drives right-lamp stutter, light-cone intensity and smoke emission. See [level rules](levels.md).
