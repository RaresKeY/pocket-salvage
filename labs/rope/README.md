# Rope lab

Open `labs/rope/lab.tscn` in Godot 4.7 and run that scene (F6). On the shared workstation use the managed Godot runner. Run `./labs/capture rope` for a background GPU screenshot; this never opens a desktop window.

Drag the mint endpoint, adjust paid-out length, pause, reset, and toggle physical points or the smooth jacket. The pillar demonstrates persistent wrapping and unwrapping. Orange dots are pinned corner contacts. The endpoint is a diagnostic handle, not a mass-bearing magnet; the next physics subsystem owns real objects. Tab/arrow/Enter navigation works with ordinary Godot Controls. The viewport fits a 1200×480 world while controls reflow independently.

The [rope module](../../scripts/rope/README.md) comes from White Approach's physical rope plus Plug & Prosper's refined drawing. It does not depend on either source game at runtime. `./tests/check` includes deterministic rope behavior and a lab startup check.
