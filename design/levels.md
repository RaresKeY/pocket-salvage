# Level selection

## User design

RaresKeY, 2026-09-25: requested a classic level grid, mostly locked, first three unlocked, clear weather first, light wind and other weather second, violent weather third. [Exact words](../prompts/source/level-grid.md).

This replaces the earlier random-weather selection in the playable round; the reusable weather system remains.

## AI-inferred design

Twelve numbered square slots, nine locked placeholders, no progression save or automatic unlocking. All three use the existing yard, ten pieces and four-minute timer. Clear, Breezy and Violent are provisional names. Replay retains the chosen level; pause/results provide a Levels action. Mouse/touch selects tiles; controller directions select unlocked levels before A starts. Six columns, four on narrow screens.

Breezy: wind 18 + gust 24 every 7–12s, rise 1.5s, grip 0.7, fog 0.18, rain 70, lightning every 35–50s with 1.4s warning and 0.35s cut, multiplier 1.2. Violent: wind 100 + gust 180 every 4–6s, rise 0.8s, grip 0.3, fog 0.3, rain 260, lightning every 8–16s with 1s warning and 1.4s cut, multiplier 1.8. These balance values are agent choices awaiting playtesting.
