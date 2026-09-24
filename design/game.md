# Game Direction

## User design

The user requested a new repository named along the lines of `random-game` for a collaboration experiment, specified private GitHub hosting, and requested that the structure reflect Jam Sync's ideas. Exact directives are recorded in [the source record](../prompts/source/repository-bootstrap.md).

The official game name is **Pocket Salvage**. Keep the repository name, checkout and upstream as `random-game`. The user-selected loop is: **control a magnetic crane, collect scrap, and sort it before the timer expires**. Audience and delivery platforms remain open.

The next agreed phase is a lightweight shared design spike, followed by a small MVP. Contributors work freeform as time allows. Preserve explicit user decisions separately from AI proposals as the game takes shape.

## AI-inferred design

Use Godot 4.7 and initially explore a 2D crane, following the reusable rope source games. A rope showcase precedes reusable [mask and collision support](physics.md); concrete object/box definitions are deferred per the user's clarification. The timed sorting round remains the eventual MVP. See [rope design](rope.md). The lab presentation does not select final game art.

Record proposed concepts here with their author and approval status before growing the prototype. Keep the initial experiment small enough that contributors can review one coherent change at a time.
