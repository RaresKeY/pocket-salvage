# HUD lab

Run `res://labs/hud/lab.tscn` through the shared Godot Podman runner. Synthetic round data demonstrates the reusable HUD without starting physics or a timer.

- 1 / 2 / 3 / 4: ready / running / paused / finished.
- P: toggle paused/running. R: return to ready.
- Click or keyboard-activate the focused start/resume/replay action.

The game control hints are presentation samples; the lab does not move a crane. [Contract](../../specs/round_hud.md), [intent](../../design/round_hud.md).
