# Pocket Salvage directive — 2026-09-24

Exact user directive:

> prepare a rope submodule for Pocket Salvage: control a magnetic crane, collect scrap, and sort it before the timer expires.
> from white approach and plug and prosper first take the code and then copy it, then from the more refined one make a submodule we can use in the game in the repo for rope physics and a lab to showcase it
> also make official name Pocket Salvage, do not change repository name though so upstream remains like before, do it in README, design, specs and whatnot
>
> also after you are done with those and they are pushed and commited
>
> make the physics subsystem itself for objects, let's make a simple masked physics to objects, the magnet, etc...
>
> then after that let's make these rules explicit in README and my local AGENTS.md: always rebase when origin is forward before push, always keep all work if conflict resolution is simple, else if conflicting such that an AI cannot keep all work or the direction is bifurcating stop and ask user direction

Exact clarification after asking whether “masked physics” meant collision channels or image-alpha geometry:

> we can delay that as just subsystem that does it, we want colision box, mask to hide parts behind for now, as for other boxes for physics keep separate, we want to make the submodule that would let use use these not the boxes themselves for now btw
