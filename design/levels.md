# Level selection

## User design

RaresKeY, 2026-09-25: requested a classic level grid, mostly locked, first three unlocked, clear weather first, light wind and other weather second, violent weather third. [Exact words](../prompts/source/level-grid.md).

This replaces the earlier random-weather selection in the playable round; the reusable weather system remains.

RaresKeY, 2026-09-25: [Blood Moon directive](../prompts/source/blood-moon.md) adds level 4 with tainted moon/sky/lights/weather, crows only, reversed heads, intermittent light/generator failure, low-to-medium random weather and smoothly reversing bounded wind.

RaresKeY, 2026-09-25: [level-flow request](../prompts/source/level-flow.md) asks for selection on startup and between levels, preceded by victory results, and Dale’s spawning design with fewer pieces initially and more later. Dale’s [recorded direction](../prompts/source/jam-polish.md) is a big starting pile; the conveyor remains a separate unapproved proposal.

## AI-inferred design

Twelve numbered square slots, eight locked placeholders, no progression save or automatic unlocking. All four use the existing yard and four-minute timer, with progressively larger starting piles. Clear, Breezy and Violent are provisional names. Explicit restart retains the chosen level; victory Continue returns to selection with the next playable level highlighted. Pause and timeout results provide a Levels action. Mouse/touch selects tiles; controller directions select unlocked levels before A starts. Six columns, four on narrow screens.

Breezy: wind 18 + gust 24 every 7–12s, rise 1.5s, grip 0.7, fog 0.18, rain 70, lightning every 35–50s with 1.4s warning and 0.35s cut, multiplier 1.2. Violent: wind 100 + gust 180 every 4–6s, rise 0.8s, grip 0.3, fog 0.3, rain 260, lightning every 8–16s with 1s warning and 1.4s cut, multiplier 1.8. These balance values are agent choices awaiting playtesting.

Blood Moon choices: retain head appearance/animations but swap materials and electrically powered behavior. Wind base 16–40, gust 18–40, rain 45–120, fog 0.10–0.28 and grip 0.55–0.85 roll once per rebuild from independent resource copies; multiplier 1.5. Direction starts randomly, holds 8–18s, then alternates through a 3s smoothstep with signed force capped at ±80. Generator waits 18–32s, right lamp stutters in eight 0.2s steps, power stops for 2–4s, then recovers. Both floodlight cones go dark during generator outage; the right lamp alone stutters. Existing smoke represents the generator exhaust, so new smoke pauses while stopped. Crimson is `(1, .32, .27)`; sky gradient is `220912`–`391721`. Light cones are the existing light masks; collision and alpha-occlusion masks keep their geometry/coverage. These are implementation choices, not separately approved balance values.

Progression choices: 4, 6, 10 and 12 pieces; non-overlapping rows `[3,1]`, `[3,2,1]`, `[4,3,2,1]` and `[4,4,4]`, retaining all three materials in each level. Victory waits for Continue, then highlights the next unlocked slot without auto-starting it. The last playable level returns to its own slot. Timeout offers Retry or Levels. No progression save or new unlock policy is added.
