# Game Direction

## User design

The user requested a new repository named along the lines of `random-game` for a collaboration experiment, specified private GitHub hosting, and requested that the structure reflect Jam Sync's ideas. Exact directives are recorded in [the source record](../prompts/source/repository-bootstrap.md).

The official game name is **Pocket Salvage**. The original instruction kept `random-game`; RaresKeY’s [2026-09-25 public-delivery request](../prompts/source/public-release.md) supersedes it with a public repository named after the game. The user-selected loop is: **control a magnetic crane, collect scrap, and sort it before the timer expires**. Audience remains open; requested public builds cover Windows, Linux and Web.

The next agreed phase is a lightweight shared design spike, followed by a small MVP. Contributors work freeform as time allows. Preserve explicit user decisions separately from AI proposals as the game takes shape.

2026-09-25, recorded in [jam polish](../prompts/source/jam-polish.md): RaresKeY asked Dale to treat the repository as their jam entry, find and solve problems, and move towards polish. Dale then set these directions: the crane gets **swappable heads**, a magnet and a gripper, that are put down and picked up ("magnet wont pick up rubber"); scrap starts as **a big pile** rather than a neat row; the yard gets a livelier background with more sprites, movement and "a moon or something"; the crane makes noise when it moves; the game gets subtle background music; the code stays DRY and reusable. RaresKeY will supply music, sound effects and UI polish, then publish builds on GitHub releases.

## AI-inferred design

Use Godot 4.7 and initially explore a 2D crane, following the reusable rope source games. A rope showcase precedes reusable [mask and collision support](physics.md); concrete object/box definitions are deferred per the user's clarification. The timed sorting round remains the eventual MVP. See [rope design](rope.md). The lab presentation does not select final game art.

Record proposed concepts here with their author and approval status before growing the prototype. Keep the initial experiment small enough that contributors can review one coherent change at a time.

2026-09-25 (Claude, for Dale): the heads split the materials so that the magnet lifts only steel and the claw lifts copper and rubber. That makes the magnet physically believable and turns the round into a routing puzzle: sort one head's materials, swap once, sort the rest. Details are in [crane](crane.md), [sorting and rounds](round.md) and [level layouts](level_layout.md).

## Open proposals

- **Conveyor** (Claude, 2026-09-25, awaiting RaresKeY): a conveyor feeds scrap in over time so a round escalates instead of being one fixed pile. The conveyor frames already exist in the Bitwright set.
- **More heads** (Claude, 2026-09-25, not requested): a suction cup for flat panels such as the car door, or a heavy hook for the engine block.
