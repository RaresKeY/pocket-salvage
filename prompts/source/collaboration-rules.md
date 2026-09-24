# Collaboration Rules — Source Excerpts

Source: explicit user direction on 2026-09-24. The excerpts preserve the original wording and spelling, with trailing whitespace trimmed; intervening conversational text is omitted.

```text
no PRs, striaght commits genreeal riles

wrap it up, we just bootstrapping
```

```text
What do you say we use this structure generally:

    main only for now, experimental branches if needed for separation
    constant specs sync but following the ideas in the jam-sync repo I shared
    no release tags, but explicit versioning in the game when we build public releases only, otherwise short sha after 0.0.0
    checkpoints and commits as required, recovery is bisect or on top
    always rebase on push commits


As this is private for now, no versioning, builds can be local reproducible and have the sha commit of convention
And for Godot version what do you have? mine is 4.7
Every other convention is from the repo and we can add more as we go, feel free to suggest
I think first we spike design (if you are okay with how I detailed the design/ structure), then we implement an MVP

And we can work on this as we have time, freeform and see if we sync? wdyt?
Oh and for conflicts: keep all work, mainly rely on AI to solve it unless it overlaps intent, I reckon we can just do commit pushes as we go so it shouldn't affect us much but we can make an explicit policy if it gets in the way
```
