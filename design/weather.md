# Weather

Status: approved by Dale and implemented on 2026-09-25 (`df5ad76`). Implementation contract: [specs/weather.md](../specs/weather.md).

## User design

Dale Mooney, 2026-09-25 ([exact record](../prompts/source/weather.md)):

- Add weather that physically affects how you work the crane.
- **Each round rolls one weather and keeps it**, so replays differ.
- First set: **Wind, Rain, Storm and Fog**, with Clear as the baseline.
- **Harder weather earns a score multiplier.**
- It must be **a DRY system that is extendable and easy to implement and integrate**.
- Dale approved the data-profile approach, and each of the three design sections below as presented.

RaresKeY’s later [level-grid request](levels.md) replaces random weather selection in the playable scene with three fixed difficulty choices.

## AI-inferred design

Everything below is Claude's proposal, approved as a whole by Dale. The numbers are starting points for playtesting, not tuned values.

### Effect on play

| Weather | Chance | Multiplier | Effect |
|---|---|---|---|
| Clear | 30% | x1.0 | None. |
| Fog | 15% | x1.2 | The yard fades with distance from the crane and bin labels dim, so bins are read by colour and symbol. No physics change. |
| Wind | 20% | x1.3 | A steady wind from a side chosen per round, plus gusts every 4 to 9 s that build over about a second. It pushes the head and airborne scrap. The force scales with a piece's size rather than its mass, so light scrap drifts more. |
| Rain | 20% | x1.3 | Scrap friction drops to about a third, so landings skid and thrown-back scrap slides further. A light breeze. |
| Storm | 15% | x1.6 | Stronger wind and bigger gusts, rain grip, and lightning every 12 to 25 s with a rumble a second before. A strike cuts power for about a second: **a magnet drops its load, a claw holds on** because it is mechanical. |

- The multiplier is applied once, at the finish, and only to a positive score, so it never deepens a negative one. Results show it as its own line, like the time bonus.
- Wind pushes only the head and scrap that is not touching anything. Resting scrap is held by friction as normal, so the pile does not blow away.

### What is physics and what is not

- **Physics:** wind is a real force each physics step (the head swings on its cable and airborne scrap drifts through Godot's rigid-body simulation). Rain changes real friction on the scrap. A power cut simply releases the load, so its fall is simulated. "Airborne" comes from real contact reports.
- **Not physics, on purpose:** the seeded schedule of gusts and strikes, fog (visual only), rain streaks and splashes (non-colliding visuals), and the drawn rope leaning with the wind. The physical cable is a massless constraint, so wind acts on the head and the cable follows.

### Architecture

Weathers are data, and effects are small reusable parts. Adding a weather is one data file. Adding a new kind of effect is one effect file.

- `scripts/weather/weather_profile.gd`: a `Resource` holding id, label, tip line, chance, multiplier, steady wind, gust strength and interval, grip scale, fog density, rain rate, lightning interval, power-cut length and sound names.
- `data/weather/*.tres`: one profile each for Clear, Fog, Wind, Rain and Storm.
- `scripts/weather/weather.gd`: the `Weather` node. It picks a profile by chance from a seeded generator, runs the gust and lightning clock, exposes the current wind, and emits `lightning_warning`, `lightning` and `power_cut(seconds)`. It lives inside the game world, so it pauses with it.
- `scripts/weather/effects/`: a shared base class plus one file per effect. Each reads only the profile fields it needs and enables itself only when the profile uses them.
  - **wind:** forces on the head and airborne scrap, plus a wind loop whose volume follows the live wind.
  - **grip:** scrap friction.
  - **rain:** streaks angled by the wind, floor splashes, a wet sheen, and a rain loop.
  - **fog:** a fade overlay and dimmed bin labels.
  - **lightning:** a screen flash, a brief bolt and thunder; asks the round for a power cut.

### Integration, kept small

- **Round controller:** an optional multiplier, recorded as `weather_bonus` beside `time_bonus`.
- **Salvage round:**
  - picks the weather when building the world (tests can force one)
  - adds the `Weather` node and gives the effects what they act on
  - gains one `power_cut(seconds)` method
- **HUD:** the start card shows the weather, multiplier and a one-line tip; a small badge shows the weather all round; results show the bonus line.
- **Presentation:** clouds speed up with the wind; weather visuals go into the existing ambience layers.
- **Sound:** `wind_loop`, `rain_loop` and `thunder` are added to the seeded generator as placeholders under names RaresKeY can replace.
- Controls, including RaresKeY's gamepad and touch input, are unaffected.

### Verification

A new `tests/weather_test.gd` checks:

- chance-weighted picking with a fixed seed
- every profile loads
- wind moves an airborne body sideways but not a resting one
- rain lowers scrap friction
- a storm power cut makes a magnet drop its load while a claw holds
- the multiplier applies once and only to a positive score
- the round starts and finishes under each forced weather

The existing ten-piece salvage test forces Clear, so it stays deterministic.

### Open questions for playtesting

- Are the chances and multipliers fair?
- Is Storm fun or just punishing?
- Should fog also hide the pile?
- Should weather ever change mid-round later? (Not in this version.)

### Implementation notes (Claude, 2026-09-25)

- Dale played the first build: wind was invisible, and he asked for it to blow the crane and make it harder (2026-09-25, [record](../prompts/source/weather.md)). Claude added gust streaks and blowing dust, a trolley drift the player steers against (`wind x 0.22` units/s), and raised Wind to 60 + 110 and Storm to 80 + 150 so a gust visibly swings the head. Still to tune by play; see [TODO](../TODO.md).
- The drawn rope does not lean with the wind: the rope solver takes no external force, and changing RaresKeY's rope module was out of scope. Deferred in TODO.
- Wind skips scrap being thrown back out of a wrong bin, so the aimed landing stays inside crane reach.
- The screenshots caught a weather badge that wrapped one letter per line and rain spilling past the yard edges; both were fixed, and the badge has a layout test.

### User visual direction, RaresKeY, 2026-09-25

[Exact request](../prompts/source/wind-ui-polish.md): retain pixel rain; use smooth curved wind lines that fade at edges; make lifted sand rare, slower, darker brown, varied and fading.

### AI-inferred visual implementation

Keep physics and rain intact. Use three bounded 32-segment antialiased ribbons with mild sinusoidal bends, faded tips and 80-unit edge fades. Dust becomes seven-particle one-shot bursts, 6–11 seconds apart after an initial delay, 22–38 units above the ground, 12–36 units/s, 0.55–1.8 scale and a dark-brown initial gradient. Dedicated cosmetic RNG avoids changing weather/gameplay rolls.

### Wind motes, 2026-09-25

User design: RaresKeY replaces lines with a dynamic dot following a randomized curve downwind, with a fading tail ([exact request](../prompts/source/wind-motes-launcher.md)).

AI-inferred design: three motes, each with two spatial sine curves, random phase/bend/frequency/speed per crossing. The original 1.2s dot-tail presentation is superseded by the faint tapered-ribbon refinement below. Motion uses the continuous signed wind direction, preserving positions through reversals. Edge fades and Blood Moon palette remain. Physics, rain and dust stay unchanged.

### Level 3 flicker and soft rain, 2026-09-25

User design (RaresKeY): [exact request and confirmation](../prompts/source/lightning-rain.md). Violent lightning briefly inverts the magnet then restores its prior state; switching off drops held scrap. Rain should primarily be non-harsh, with slight, normal and violent strengths.

AI-inferred design: 0.45s inversion on Level 3 only. Overlapping strikes extend the same flicker, pause freezes it, manual toggling cancels restoration, and head changes/restart/results discard stale restoration. Other levels retain their power-cut rules, including Blood Moon’s reversed powered head. Rain particle rates select slight below 100, normal below 200, violent at 200 or above; the existing weather profiles remain unchanged apart from Violent’s flicker duration/tip.

### Faint tapered wind, 2026-09-25

User design (RaresKeY): [exact request](../prompts/source/wind-ribbons.md) replaces the conceptual dot with a faint vertical head, a wider front and a much longer progressively narrowing tail.

AI-inferred design: keep the existing randomized curves and continuous directional movement. Use a 4–5.5 unit vertical front flush with the ribbon, taper its width to zero over 4.5s of history (30Hz, at most 144 points), and reduce opacity to 0.055–0.12. Retain quadratic age and boundary fades. One indexed mesh per ribbon with transparent edge strips gives smooth variable width without a draw call per segment; the leading edge is a faint 0.8-unit stroke, not a bright round marker. This changes visual wind only; forces, weather audio and dust retain their current behavior.

AI-inferred edge handling: fade the whole long ribbon as its head reaches the yard edge, preserving the existing per-point boundary fade; this hides the history reset on wrap.

### Weather intensity, 2026-09-25

AI-inferred, for Level 5 Storm (see [levels](levels.md)): the weather node has an intensity from 0 to 1, default 1, that level events set. Wind force, fog density and rain visibility and volume scale with it, and lightning waits while it is under 0.8. Other levels never change it.
