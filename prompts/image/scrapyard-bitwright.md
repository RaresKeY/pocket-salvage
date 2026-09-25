# Scrapyard sprite set (Bitwright)

Exact generation requests for every Pocket Salvage sprite drawn by Dale Mooney's Bitwright, copied verbatim from the `scrapyard` set in Bitwright's `content/sprite-sets.json`. The prompt text is the `want` field; nothing below is reconstructed from memory.

## Record

- Tool: Bitwright `tools/sprite/draw-set.ts --set scrapyard`, later runs with `--append` (draws only subjects not yet in the set). Every subject after the anchor is matched to the anchor (the magnet) for palette; `like` matches a subject to an earlier one instead.
- Set purpose (`why`): Pocket Salvage pitch: a physics scrapyard game where a magnetic crane on a rope picks up scrap and sorts it into bins before the timer runs out.
- View: `front`. Output spec: Bitwright `specs/game/scrapyard.json`.
- Render and import: `npx tsx tools/sprite/render-game.ts --set scrapyard --out <dir>` in Bitwright, then `python3 tools/pixel_art/import_bitwright.py <dir> [key ...]` here, which copies frames under game names into `assets/bitwright/` and makes exact 8x copies with provenance through `tools/pixel_art/superscale.gd`. The first 28 were copied by hand as PNGs (commit `f315834`), masks followed in `3cec96b`.
- Spend: first 28 draws 189p (2026-09-24). Additions on 2026-09-25: ten background subjects 79p, `gull_perched` about 8p, `claw` and `stand` 19p.
- Status: all outputs below are selected and in use, except the conveyor frames, which are in the scene preview only.

## 2026-09-24: original set (28)

### `magnet` (anchor)

```text
a heavy industrial crane electromagnet seen side on: a round flat steel disc with a thick rim, yellow and black hazard stripes around its side, a lifting eye on top, and a glowing blue coil face underneath that pulses
```

Settings: size: [40, 24], motion: "loop".
Outputs: `assets/bitwright/crane_magnet_01.png`, `assets/bitwright/crane_magnet_02.png`, `assets/bitwright/crane_magnet_03.png`, `assets/bitwright/crane_magnet_04.png`, `assets/bitwright/crane_magnet_05.png`, `assets/bitwright/crane_magnet_06.png` (8x copies under `assets/bitwright_8x/`).

### `chain`

```text
a single steel chain link for a crane cable, one oval link, drawn tight to the canvas
```

Settings: size: [8, 12].
Outputs: `assets/bitwright/crane_chain_link.png` (8x copies under `assets/bitwright_8x/`).

### `trolley`

```text
a crane trolley seen side on that rolls along an overhead rail: a yellow painted steel box with two small wheels on top and a cable winch drum underneath
```

Settings: size: [32, 20].
Outputs: `assets/bitwright/crane_trolley.png` (8x copies under `assets/bitwright_8x/`).

### `rail`

```text
an overhead steel I-beam gantry rail seen side on, yellow paint worn to bare steel with rivets, filling the canvas edge to edge, made to repeat sideways
```

Settings: size: [16, 16], tile: {"x": true}.
Outputs: `assets/bitwright/crane_rail_tile.png` (8x copies under `assets/bitwright_8x/`).

### `tower`

```text
a tall crane support tower seen side on: a yellow steel lattice pillar with diagonal cross bracing and a hazard striped foot
```

Settings: size: [24, 64].
Outputs: `assets/bitwright/crane_tower.png` (8x copies under `assets/bitwright_8x/`).

### `tire`

```text
an old worn black rubber car tyre seen side on as a circle, chunky tread and a grey hubless centre, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [24, 24].
Outputs: `assets/bitwright/scrap_tire.png` (8x copies under `assets/bitwright_8x/`).

### `drum`

```text
a dented oil drum lying upright, rusty red paint with two ribs and a chipped white stripe, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [20, 28].
Outputs: `assets/bitwright/scrap_oil_drum.png` (8x copies under `assets/bitwright_8x/`).

### `door`

```text
a scrapped blue car door with a broken window and a chrome handle, dented and rusty at the edges, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [32, 28].
Outputs: `assets/bitwright/scrap_car_door.png` (8x copies under `assets/bitwright_8x/`).

### `engine`

```text
a greasy grey car engine block with cylinder heads, a pulley on the front and a few loose wires, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [32, 24].
Outputs: `assets/bitwright/scrap_engine_block.png` (8x copies under `assets/bitwright_8x/`).

### `pipe`

```text
a bent rusty steel pipe with a flange at one end, lying at a slight angle, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [32, 12].
Outputs: `assets/bitwright/scrap_bent_pipe.png` (8x copies under `assets/bitwright_8x/`).

### `cog`

```text
a large steel cog wheel with a hole in the middle and a few rust spots, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [20, 20].
Outputs: `assets/bitwright/scrap_cog.png` (8x copies under `assets/bitwright_8x/`).

### `washer`

```text
a scrapped white washing machine with a round glass door, a dent in the side and a rust streak, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [24, 28].
Outputs: `assets/bitwright/scrap_washing_machine.png` (8x copies under `assets/bitwright_8x/`).

### `hubcap`

```text
a shiny chrome car hubcap seen face on, a round disc with spokes and a scuff, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [16, 16].
Outputs: `assets/bitwright/scrap_hubcap.png` (8x copies under `assets/bitwright_8x/`).

### `spring`

```text
a big coiled steel suspension spring standing upright, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [12, 20].
Outputs: `assets/bitwright/scrap_spring.png` (8x copies under `assets/bitwright_8x/`).

### `girder`

```text
a short rusty steel girder, an I-beam section with rivet holes, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [40, 10].
Outputs: `assets/bitwright/scrap_girder.png` (8x copies under `assets/bitwright_8x/`).

### `battery`

```text
a car battery, a black plastic box with red and black terminals on top and a yellow warning label, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [18, 14].
Outputs: `assets/bitwright/scrap_car_battery.png` (8x copies under `assets/bitwright_8x/`).

### `can`

```text
a crushed tin can, silver with a faded red label, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [10, 10].
Outputs: `assets/bitwright/scrap_tin_can.png` (8x copies under `assets/bitwright_8x/`).

### `coil`

```text
a tangled bundle of shiny copper wire, orange and bright, seen side on, drawn tight to the canvas with no ground, no shadow and no margin, so it can be a physics body
```

Settings: size: [18, 14].
Outputs: `assets/bitwright/scrap_copper_wire.png` (8x copies under `assets/bitwright_8x/`).

### `bin_steel`

```text
a big open topped scrap skip seen side on, painted blue with a white cog symbol on its side, empty and ready to catch scrap
```

Settings: size: [48, 32].
Outputs: `assets/bitwright/bin_steel.png` (8x copies under `assets/bitwright_8x/`).

### `bin_copper`

```text
the same scrap skip painted orange with a white lightning bolt symbol on its side
```

Settings: size: [48, 32], like: "bin_steel".
Outputs: `assets/bitwright/bin_copper.png` (8x copies under `assets/bitwright_8x/`).

### `bin_rubber`

```text
the same scrap skip painted green with a white circle tyre symbol on its side
```

Settings: size: [48, 32], like: "bin_steel".
Outputs: `assets/bitwright/bin_rubber.png` (8x copies under `assets/bitwright_8x/`).

### `conveyor`

```text
a scrapyard conveyor belt seen side on, a dark rubber belt over steel rollers with yellow side plates, the belt ridges scrolling along
```

Settings: size: [16, 12], motion: "loop", tile: {"x": true}.
Outputs: `assets/bitwright/conveyor_belt_tile_01.png`, `assets/bitwright/conveyor_belt_tile_02.png`, `assets/bitwright/conveyor_belt_tile_03.png`, `assets/bitwright/conveyor_belt_tile_04.png`, `assets/bitwright/conveyor_belt_tile_05.png`, `assets/bitwright/conveyor_belt_tile_06.png` (8x copies under `assets/bitwright_8x/`).

### `ground`

```text
packed scrapyard dirt with oily gravel and small bits of metal in it, filling the canvas edge to edge, made to repeat, cracks stop short of the edges
```

Settings: size: [16, 16], tile: true.
Outputs: `assets/bitwright/ground_dirt_tile.png` (8x copies under `assets/bitwright_8x/`).

### `backdrop`

```text
a distant scrapyard at dusk: piles of crushed cars and scrap heaps in dark muted purples and browns, a chain link fence in front, filling the whole width and made to repeat sideways
```

Settings: size: [160, 64], tile: {"x": true}.
Outputs: `assets/bitwright/backdrop_scrapyard_tile.png` (8x copies under `assets/bitwright_8x/`).

### `spark`

```text
a burst of bright yellow and white welding sparks flying out from a point and fading over the frames
```

Settings: size: [24, 24], motion: "loop".
Outputs: `assets/bitwright/fx_sparks_01.png`, `assets/bitwright/fx_sparks_02.png`, `assets/bitwright/fx_sparks_03.png`, `assets/bitwright/fx_sparks_04.png`, `assets/bitwright/fx_sparks_05.png`, `assets/bitwright/fx_sparks_06.png` (8x copies under `assets/bitwright_8x/`).

### `dust`

```text
a small puff of grey brown dust that expands and fades over the frames, as when scrap lands on the ground
```

Settings: size: [24, 16], motion: "loop".
Outputs: `assets/bitwright/fx_dust_01.png`, `assets/bitwright/fx_dust_02.png`, `assets/bitwright/fx_dust_03.png`, `assets/bitwright/fx_dust_04.png`, `assets/bitwright/fx_dust_05.png`, `assets/bitwright/fx_dust_06.png` (8x copies under `assets/bitwright_8x/`).

### `timer`

```text
a round yellow stopwatch icon with a black hand and a button on top, for a game HUD
```

Settings: size: [16, 16].
Outputs: `assets/bitwright/hud_timer.png` (8x copies under `assets/bitwright_8x/`).

### `coin`

```text
a scrap coin icon for a game HUD: a gold coin with a small cog stamped in it
```

Settings: size: [12, 12].
Outputs: `assets/bitwright/hud_coin.png` (8x copies under `assets/bitwright_8x/`).

## 2026-09-25: additions (13)

Requested by Dale for the night scene, perching gulls and swappable crane heads; see [the directive record](../source/jam-polish.md).

### `moon`

```text
a big pale full moon over a scrapyard at night, soft grey craters and a faint pale rim, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [32, 32].
Outputs: `assets/bitwright/backdrop_moon.png` (8x copies under `assets/bitwright_8x/`).

### `cloud`

```text
one long thin wispy night cloud, dusky purple grey with a pale moonlit top edge, soft ragged ends, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [48, 12].
Outputs: `assets/bitwright/backdrop_cloud.png` (8x copies under `assets/bitwright_8x/`).

### `skyline`

```text
a distant scrapyard skyline silhouette at night in dark dusky purple: heaps of scrap, a derelict crane jib and a crushed car stack, only a few lighter edges, filling the canvas edge to edge, made to repeat sideways
```

Settings: size: [64, 32], tile: {"x": true}.
Outputs: `assets/bitwright/backdrop_skyline_tile.png` (8x copies under `assets/bitwright_8x/`).

### `heap`

```text
a heap of mixed junk: old tyres, bent pipes, a car bonnet and a fridge piled together, dim and slightly shadowed as scenery behind a fence, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [64, 28].
Outputs: `assets/bitwright/backdrop_junk_heap.png` (8x copies under `assets/bitwright_8x/`).

### `floodlight`

```text
a tall scrapyard floodlight: a thin grey steel pole with a bank of four bright white lamps on a crossbar at the top, glowing, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [20, 56].
Outputs: `assets/bitwright/yard_floodlight.png` (8x copies under `assets/bitwright_8x/`).

### `beacon`

```text
a small round amber warning beacon lamp that flashes on and off, a dark base and a glass dome that lights up bright orange
```

Settings: size: [8, 8], motion: "loop".
Outputs: `assets/bitwright/yard_beacon_01.png`, `assets/bitwright/yard_beacon_02.png`, `assets/bitwright/yard_beacon_03.png`, `assets/bitwright/yard_beacon_04.png`, `assets/bitwright/yard_beacon_05.png`, `assets/bitwright/yard_beacon_06.png` (8x copies under `assets/bitwright_8x/`).

### `smoke`

```text
a small puff of grey smoke that rises, swells and fades away, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [16, 16], motion: "loop".
Outputs: `assets/bitwright/fx_smoke_01.png`, `assets/bitwright/fx_smoke_02.png`, `assets/bitwright/fx_smoke_03.png`, `assets/bitwright/fx_smoke_04.png`, `assets/bitwright/fx_smoke_05.png`, `assets/bitwright/fx_smoke_06.png` (8x copies under `assets/bitwright_8x/`).

### `gull`

```text
a white seagull flying side on facing right, grey wing tips, wings flapping up and down, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [16, 12], motion: "loop".
Outputs: `assets/bitwright/critter_gull_01.png`, `assets/bitwright/critter_gull_02.png`, `assets/bitwright/critter_gull_03.png`, `assets/bitwright/critter_gull_04.png` (8x copies under `assets/bitwright_8x/`).

### `crow`

```text
a black crow perched facing left, head bobbing and pecking, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [12, 12], motion: "loop".
Outputs: `assets/bitwright/critter_crow_01.png`, `assets/bitwright/critter_crow_02.png`, `assets/bitwright/critter_crow_03.png`, `assets/bitwright/critter_crow_04.png`, `assets/bitwright/critter_crow_05.png`, `assets/bitwright/critter_crow_06.png` (8x copies under `assets/bitwright_8x/`).

### `rat`

```text
a scruffy grey scrapyard rat running side on facing right, legs scurrying and a long pink tail, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [16, 10], motion: "loop".
Outputs: `assets/bitwright/critter_rat_01.png`, `assets/bitwright/critter_rat_02.png`, `assets/bitwright/critter_rat_03.png`, `assets/bitwright/critter_rat_04.png` (8x copies under `assets/bitwright_8x/`).

### `gull_perched`

```text
the same white seagull standing perched side on facing right, wings folded, grey back, orange beak, turning its head left and right and ruffling, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [16, 12], motion: "loop", like: "gull".
Outputs: `assets/bitwright/critter_gull_perched_01.png`, `assets/bitwright/critter_gull_perched_02.png`, `assets/bitwright/critter_gull_perched_03.png`, `assets/bitwright/critter_gull_perched_04.png` (8x copies under `assets/bitwright_8x/`).

### `claw`

```text
a heavy industrial crane grabber claw head seen side on: a steel hub with the same yellow and black hazard stripes and lifting eye on top, and three curved steel jaws underneath that close together to grip and then open again
```

Settings: size: [40, 28], motion: "loop".
Outputs: `assets/bitwright/crane_claw_01.png`, `assets/bitwright/crane_claw_02.png`, `assets/bitwright/crane_claw_03.png`, `assets/bitwright/crane_claw_04.png`, `assets/bitwright/crane_claw_05.png`, `assets/bitwright/crane_claw_06.png` (8x copies under `assets/bitwright_8x/`).

### `stand`

```text
a low steel tool stand on the scrapyard floor for parking a spare crane head: a sturdy yellow and black hazard striped frame with a flat cradle on top and bolted feet, empty, drawn tight to the canvas with no ground and no shadow
```

Settings: size: [48, 20].
Outputs: `assets/bitwright/tool_stand.png` (8x copies under `assets/bitwright_8x/`).

## Blood Moon additions, 2026-09-25

Drawn for a tint-versus-generated comparison requested by RaresKeY. He chose the generated moon, rejected the first skyline because its sky repeated moons, and asked for a redraw without them. Cloud and fence were not used; the tint covers them.

### blood_moon

```
the same big full moon but a blood moon: deep crimson red with darker red craters and a faint orange rim glow, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [32, 32], like: moon. Status: selected.
Output: `assets/bitwright/backdrop_blood_moon.png` (8x copy under `assets/bitwright_8x/`).

### blood_cloud

```
the same long thin wispy night cloud under a blood moon: dark maroon with a crimson lit top edge, soft ragged ends, drawn tight to the canvas with no ground and no shadow, for a game background
```

Settings: size: [48, 12], like: cloud. Status: rejected.

### blood_skyline (first draw)

```
the same distant scrapyard skyline silhouette but under a blood moon: near black maroon silhouettes of scrap heaps, a derelict crane jib and a crushed car stack against a deep crimson sky, a few red lit edges, filling the canvas edge to edge, made to repeat sideways
```

Settings: size: [64, 32], tile: x, like: skyline. Status: rejected.

### blood_fence

```
the same scrapyard chain link fence backdrop under a blood moon: grey steel fence posts and rails lit dull red, dark maroon piles of crushed cars and scrap behind the fence, a crimson sky strip along the top, filling the whole width and made to repeat sideways
```

Settings: size: [160, 64], tile: x, like: backdrop. Status: rejected.

### blood_skyline

```
the same distant scrapyard skyline silhouette under a blood moon: near black maroon silhouettes of scrap heaps, a derelict crane jib and a crushed car stack against a deep crimson sky with a few red lit edges; the sky is plain, with no moon, no circles, no discs, no lamps and no bright spots anywhere, filling the canvas edge to edge, made to repeat sideways
```

Settings: size: [64, 32], tile: x, like: skyline (redraw-key). Status: selected.
Output: `assets/bitwright/backdrop_blood_skyline_tile.png` (8x copy under `assets/bitwright_8x/`).

### tornado and dust_swirl (dropped)

```
a tornado twister: a curved cone of swirling grey wind shaped like an upside down triangle, wide at the top edge and tapering to a thin point at the bottom centre, made of diagonal curved bands of pale grey and brown dust with dark gaps between them so the background shows through, ragged see through edges, a few tiny scraps spinning beside it, the bands slide sideways as it spins, transparent background outside the cone, no ground, no box, no frame
```

```
a small swirl of blowing dust low on the ground: a flat spiral of light brown dust puffs and specks curling round, loose and see through with lots of transparent gaps, no container, no bucket, no basket, no box, transparent background, the puffs rotate round the spiral
```

Settings: tornado 48x96, dust_swirl 32x24, motion loop, appended to the scrapyard set. Status: rejected. The first wording drew a rectangle and a basket; this second wording drew stacked plates, which Dale said looked odd. The twister is drawn in code instead (`scripts/level/tornado.gd`).
