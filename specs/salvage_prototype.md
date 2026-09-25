# Playable subsystem integration

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`.

## Composition

`labs/salvage/lab.tscn` composes crane suspension, round/bin, HUD, level layout, ambience and audio modules without replacing the static yard preview. `scripts/scene/yard_preview.gd` adds Play prototype; F2 returns (hidden in `standalone` exports, which start this scene directly). Each subsystem keeps its own lab and verification. The world renders into a native-resolution SubViewport between the HUD bands (100px above, 121px below), fitting 1200×480 world units with preserved aspect ratio. Placements come from [the layout module](level_layout.md), variant 0.

Ten caller-configured RigidBody2D payloads (`payload.gd`, layer 2) start as a heap; three bins share walls (layer 1); the magnet body is layer 4. Payloads use rectangle shapes and 8× art scaled to their rectangle. Bin art stays axis-aligned; masks are not integrated. `payload.grip_offset()` is the middle of whichever edge currently faces up, so tumbled scrap stays reachable; `grip_point()` is its world position. Payloads emit `landed(at)` on contact while falling faster than 160 units/s.

## Heads and stands

The crane carries one swappable head from [`crane_heads.gd`](crane.md): the magnet grips steel, the claw grips copper and rubber, and the bare hook grips nothing. Pickup takes the nearest grippable piece whose grip point is within `PICKUP_RANGE` (62) of `head_mount()` (the head's underside), with a layer-1 ray check, one piece at a time. A head over only ungrippable scrap names the head needed. The magnet engages when switched on; the claw arms open ("Claw READY") and shuts, with its sound, only on a catch. Pieces resting on a lifted one can ride along.

Two solid tool stands sit at `layout.tool_stand` and 80 units right (`STAND_GAP`); the first starts holding the claw. `stand_under_head()` finds a stand within `STAND_REACH` (34, 26) of the head's underside. `use_stand()` (E) parks the fitted head on an empty stand, or fits the head waiting on a stand to the bare hook; it refuses while carrying, away from a stand, or on the wrong kind of stand, with feedback.

## Controls

A/D or arrows move the trolley at 220 units/s within x80 to 1120; W/S or arrows change cable length at 130 units/s within 50 to 335. The magnet is a rigid body with a top cable pivot, bottom load mount and ±35° tilt cap; the attached load exchanges equal/opposite spring forces with it. Space toggles the grip, E uses a stand, M mutes music, P/Escape pauses, R rebuilds and restarts, Enter or the modal button starts. Focus loss pauses. Pausing disables world simulation while keeping timer, bodies and attachment.

## Round rules

`ROUND_SECONDS` is 240. A released piece in the matching bin scores +100 and is retired. A wrong bin scores −25 (the score may go negative) and lobs the piece to `REJECT_CLEARANCE` (120) units in front of the leftmost bin, clear of its wall and within reach, so it must still be sorted. Sorting all ten correctly ends the round with 5 points per remaining whole second; reaching zero ends it without. Either end releases the load, disables bins and shows results. The HUD receives snapshots and never owns state.

## Presentation

Heads animate from their own frames. `scripts/fx/burst_2d.gd` plays sparks at the grip point on pickup, at a correct sort and at a stand swap, and dust on `landed`. Floating +100 / −25 numbers rise from sorted or refused pieces; scrap of mass 1.5 or more shakes the stage by up to 5 units on landing; the HUD timer pulses red for the last 10 seconds. The night scenery is [`yard_ambience.gd`](level_layout.md) and keeps animating on the start, pause and results screens.

## Audio

Effects, motor loops and music come from [`scripts/audio/sfx.gd`](audio.md). The lab plays start, grip/release per head, pickup, clank on a swap, landing, correct, wrong plus eject, a tick each second of the last 10 and finish; it sets the trolley and winch loops from actual travel and reel speed each move and silences them when the round is not running.

## Verification

`tests/salvage_test.gd` drives a full round through physics without teleporting payloads: grip on the upward face of rotated pieces, the magnet never lifting copper or rubber, E refused away from a stand, a deliberate wrong-bin drop thrown back in front of the bins and later sorted, all steel with the magnet, a park-and-fetch swap to the claw, the armed claw waiting open and shutting on a catch, the rest sorted, score equal to 100 per correct minus 25 per wrong plus the time bonus, the results text, pause while carrying, restart restoring heads and stands, motor levels for travel, reel, idle, end stop and pause, music mute, timeout release and disabled end-state sensors. `salvage_navigation_test.gd` checks mouse launch/start, Space grip, P pause, mouse resume, R restart and F2 return. Tests establish deterministic playability; human playtesting decides whether it is fun.

2026-09-25 validation: full `tests/run_checks.py` passes on Windows Godot 4.7 (17 marked checks). The ten-piece round with one head swap completes in 170.05 simulated seconds of 240. Windowed screenshots checked; Gamescope/GPU captures not rerun.

History: on 2026-09-24 the six-piece prototype passed `./tests/check`, six correct deliveries in 92.38 simulated seconds, and Gamescope captures at five window sizes on an RTX 2080 Ti.
