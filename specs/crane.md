# Suspension and force attachment

Reviewed: 2026-09-24, implementation introduced alongside this spec.

`scripts/crane/suspension_2d.gd` extends the existing rope subsystem with a caller-owned `CharacterBody2D` endpoint and optional force attachment to any caller-owned `RigidBody2D`. No concrete magnet/scrap object or geometry catalog is defined.

`configure(tip, anchor, cable_length, polygons=[])` accepts world-space anchor and static rope obstacles. Callers own endpoint geometry/channels, positioning, control input and pickup eligibility. Set `anchor` and `cable_length` to move/reel. `attach(body, local_offset=Vector2.ZERO)` returns success; `detach()` preserves physical momentum. `attachment_changed(body)` emits the attached body or null. Setting `enabled=false` detaches and rejects new attachment; endpoint simulation continues. `reset(tip_position)` clears attachment and endpoint velocity. `attached_body` and `blocked` expose status.

At 60 Hz, gravity advances the endpoint with collision-aware `move_and_slide`, rope positional correction uses `move_and_collide`, then the rope steps. An offset damped spring applies bounded force to an attached body; its rotation and collision remain active. Attached bodies remain awake; detach wakes a settled load so gravity resumes. Spring, damping, gravity and force cap are public tuning fields. There is no mass feedback into the endpoint, breakage, automatic selection, material policy or final handling claim. Callers must keep initial endpoints out of solids and provide valid lengths, endpoint shapes and appropriate channels.

`labs/crane/lab.tscn` demonstrates anchor motion, reeling, nearby attachment, lifting, release and swing using plain diagnostic shapes. Its floor and rectangle dimensions and layer allocation are fixture decisions only. `tests/crane_test.gd` checks actual force lift, release/gravity, rope length and disabling. Existing rope and physics tests retain ownership of obstacle wrapping and collision-part contracts.
