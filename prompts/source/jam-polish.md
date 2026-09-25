# Jam polish directives, 2026-09-25

Dale Mooney's words from the session in which he, working through Claude Code, treated the repository as a jam entry. Spelling and punctuation are corrected; the wording and meaning are unchanged. Commentary sits outside the quotes. Design documents cite this record for the **User design** side of the split.

## RaresKeY, relayed by Dale

The session's starting brief, forwarded by Dale:

> "hey Darwin, Morning, can I ask if you have time to code today? I would like you to try and find what the repo we started together needs, and treat it as if it was our jam entry, find and solve problems on it and move towards polish.
>
> I want to assess how you deal with that part since yesterday you only did one delegated task for the art." That's what he's asked me. Can you review?

## Dale

Approving the AI review's first proposals (wrong-bin scrap counted as sorted, score floored at zero, no reward for speed, then an art pass using the unused sprites):

> Yes.

> Can you run the game?

> What next?

Bug report after playing:

> Items can get stuck between the bins and cause issues.

Head attachments, first message:

> Maybe you have a magnet head and also a gripper, so you pick up things that can't be picked up by the magnet, and different types of heads you put down and pick up new ones, etc.

Background and polish:

> And it would be good to improve the background with more sprites and movement? A moon or something, and other things to make it exciting, and add lots of nice polish and any other sprites we can add.

> How's it going?

Approving the AI's proposed list (animated sky, stars, clouds, blinking tower lights, score popups, hurry timer, screen shake, and new Bitwright sprites: moon, gull, crow, rat, floodlight, skyline, smoke, beacon):

> Yes, do it all, let's get it nice and polished.

Seagull feedback after playing:

> The seagulls repeat a lot, so they look odd and not natural, and it would be good if they landed sometimes.

Crane sound:

> When the machine moves down it doesn't make a noise, or when moving.

Head attachments, second message:

> And what about the different head attachments? Because the magnet won't pick up rubber.

Scrap arrangement:

> And maybe we add a big pile rather than all nicely placed next to each other.

Code quality:

> We also need to make sure the code is DRY and reusable.

Claw feedback after playing:

> The claws close too soon, and not as you get to the item to pick it up.

Music:

> We need some background music too, something subtle.

Wrapping up:

> OK, can we push and then give me an update for him to send?

> Nope, sent to him.

## RaresKeY

Reply after playing the pushed build, forwarded by Dale:

> Alright, nice I played it and it definitely feels polished towards a good direction, good work!
> One thing: design and specs lagged behind for this please make an AGENTS.md and CLAUDE.md, nothing fancy needed in there, just: always read specs and compactly update when making changes following rules, same for design, the agent will separate what you instructed from its inference from rules (of course you can make it explicit in there as well)
>
> Anyway I really like the changes, the animations, smart combination of lights and masks animals background and the claw/magnet, it's all top tier design.
>
> I'll prep some music and sfx as well as a bit of UI polish to bring it together then push builds on release on gh, can you bring design and specs up to date? mainly since it lagged behind here and you have the logs I would ask the agent to look at chat logs and infer from that the human/AI inferred split to keep it up to date
>
> all in all very good work, I think we can work well together, also please let me know how the flow felt and if you want change in any direction
