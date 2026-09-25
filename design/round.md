# Sorting and round intent

## User design

The selected game loop is a magnetic crane collecting and sorting scrap before a timer expires. Develop reusable subsystems in focused lab scenes, documenting intent and implementation continuously, then combine experiments incrementally. Existing physics component scope remains independent of concrete gameplay objects.

2026-09-25 ([jam polish](../prompts/source/jam-polish.md)): Dale approved ("yess") the AI review's proposal to fix three rule problems: a wrong bin swallowed the item yet counted it as sorted, the score floor hid early penalties, and finishing early earned nothing. Dale asked for a big pile of scrap and for swappable heads, which set the item count and a head swap inside the round.

## AI-inferred design

A manually clocked round model makes deterministic testing and pause ownership explicit. A released-body overlap sensor demonstrates sorting without coupling the round to a crane. Release-only capture prevents counting carried scrap crossing a bin.

Scoring (Claude, 2026-09-25, the approved fixes): +100 for a correct sort; a wrong bin costs 25 with **no floor**, so an early mistake shows, and **throws the item back out** so it must still be sorted. The round ends "all sorted" only when every item is sorted correctly, adding **5 points per whole second left**, so speed is worth replaying for. Timeout ends with no bonus.

The thrown-back item follows a computed arc to a landing point the caller chooses. The salvage round lands it 120 units in front of the first bin, clear of the bin wall and inside crane reach; an earlier 60-unit landing let small scrap skid against the wall out of reach. Neighbouring bins share a wall so no gap can trap scrap, each rim carries a small peak, and a rim sensor nudges off anything that falls asleep balanced there.

Round length is **240 seconds** for ten items and one head swap. A scripted player sorts everything in about 170 simulated seconds; humans need a playtest. The sorting lab keeps its own 45-second diagnostic round.

Scrap resting on the piece being lifted can ride along and land in the wrong bin. That is left as fair physics for now, and it is an open decision (see [TODO](../TODO.md)).

Trial bins use caller-authored rectangular walls and separate sensors, with 8× contributed sprites for visual context. Sensor acceptance is overlap, not full containment or settled motion; playtesting decides whether that should change. Future object definitions and precise collision silhouettes remain deferred.

Implementation contract and verification: [sorting and timed round](../specs/round.md).
