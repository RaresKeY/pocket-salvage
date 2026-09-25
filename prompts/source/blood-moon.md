# Blood Moon — RaresKeY, 2026-09-25

> make a blood moon level, where moon changes colod and sky is tainted, also not white birds or rats will be present as animals just crows
> the magnet and claws reverse functionality and lights+masks get tainted color as well, with right side light malfunctioning, tempo is old lightbulb mafunctining from time to time, generator stops
> wheater effects get taint color, tihs is level 4, wheater is random here in between low and medium
>
> also add wind direction state, on blood moon it goes left or right, state is random for duration then switch, with smooth transition to new value, -+ caps

## Lighting refinement

> for blood moon scene/level: mask only bulbs of light post to red not the pole same with lights on top corners, also add a screenspace red tint ovelay and a slight edge/indirect light tint on assets, maybe 5%

## Tint or generated art (relayed by Dale)

> for blood moon I think we can taint color, maybe we don't need to gen, but we can try both, the color taint looks okay, we have to mask some assets so they don't fully taint though

After the comparison screenshots:

> the moon in C, not the city scape it duplicates moons
> screen space taint + light taint (I also pushed something related, modify as needed)
> I think instead of backgrop tint, we do stronger sky tint, on masked and light, 5% on other assets, and slight tint on screenspace

> and maybe a new city scape from c but without the moon duplicates actually

Dale, 2026-09-25 (spelling corrected):

> Can we improve that skyline, as it repeats over and over?

## Tint controls (relayed by Dale)

> The tint looks okay, we might get better polish, but maybe segment them to assets/sky/screenspace/light/masked light bulbs
> and add sliders in the developer options, minmax in between sensible values and default what we have atm, but honestly I think it looks okay, for dev options(they show on play.sh in pause menu, I put collision boxes there
