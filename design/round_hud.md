# Round HUD intent

## User design

Build reusable subsystems with focused labs, documenting intent in design and current implementation in specs. Iterate independently and integrate proven pieces toward a fun game. The selected game loop is magnetic-crane scrap sorting before time expires.

## AI-inferred design

The first playable prototype needs score, remaining time, delivery progress, magnet/load status, a concise feedback line, and discoverable controls. Keep those at the screen edges so the yard remains usable. Use the existing mint/dark presentation and system font, with explicit text alongside state colors.

Ready, paused and finished states present one clear focused action: start, resume or replay. Show correct/wrong totals at completion. The HUD should consume a small presentation dictionary and emit requests, allowing a standalone lab to prove layout and interaction without physics or round logic.

Exact scoring language, feedback wording, final styling and final control bindings remain provisional. The lab's synthetic numbers do not select gameplay balance. See [implementation contract](../specs/round_hud.md).
