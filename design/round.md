# Sorting and round intent

## User design

The selected game loop is a magnetic crane collecting and sorting scrap before a timer expires. Develop reusable subsystems in focused lab scenes, documenting intent and implementation continuously, then combine experiments incrementally. Existing physics component scope remains independent of concrete gameplay objects.

## AI-inferred experiment

A manually clocked round model makes deterministic testing and pause ownership explicit. A released-body overlap sensor demonstrates sorting without coupling the round to a crane. Trial scoring is +100 correct and −25 incorrect, clamped at zero; trial round length is 90 seconds. A diagnostic lab uses a shorter 45-second round. Completing all configured items ends early. These are tunable proposals, not approved balance or final gameplay design.

Trial bins use caller-authored rectangular walls and separate sensors, with 8× contributed sprites for visual context. Decide through combined playtesting whether sorting should require full containment, settled motion, a dwell time, or merely overlap. Release-only capture prevents counting carried scrap crossing a bin. Future object definitions and precise collision silhouettes remain deferred.

Implementation contract and verification: [sorting and timed round](../specs/round.md).
