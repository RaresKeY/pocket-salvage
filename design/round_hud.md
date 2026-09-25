# Round HUD intent

## User design

Build reusable subsystems with focused labs, documenting intent in design and current implementation in specs. Iterate independently and integrate proven pieces toward a fun game. The selected game loop is magnetic-crane scrap sorting before time expires.

2026-09-25 ([jam polish](../prompts/source/jam-polish.md)): Dale approved ("yes do it all") the AI's polish list, which included floating score numbers and a hurry timer. RaresKeY plans further UI polish.

## AI-inferred design

The first playable prototype needs score, remaining time, delivery progress, head/load status, a concise feedback line, and discoverable controls. Keep those at the screen edges so the yard remains usable. Use the existing mint/dark presentation and system font, with explicit text alongside state colors.

Ready, paused and finished states present one clear focused action: start, resume or replay. Show correct/wrong totals at completion, plus the time bonus when one was earned. The HUD should consume a small presentation dictionary and emit requests, allowing a standalone lab to prove layout and interaction without physics or round logic.

2026-09-25 additions (Claude): the contributed coin and timer icons sit beside score and time; the time turns red and pulses in the last 10 seconds; "Sorted" counts correct sorts only; the status line names the fitted head and its state ("Magnet ON", "Claw READY", "Bare hook") through a caller-supplied `grip_label`; the controls footer lists Space grip, E swap head at a stand and M music. Feedback lines explain refusals ("The magnet won't hold rubber. Swap to the claw at the tool stands (E).") so the head rule teaches itself.

Exact scoring language, feedback wording, final styling and final control bindings remain provisional pending RaresKeY's UI pass. The lab's synthetic numbers do not select gameplay balance. See [implementation contract](../specs/round_hud.md).

## Compact follow-up, 2026-09-25

User design (RaresKeY): [exact request](../prompts/source/audio-ui-release.md) to compactly simplify using Supper Guard and Plug Charge. AI-inferred choices: single-row status, shorter footer, measured yard clearances, clear primary action and separate Music/SFX toggles above modals. Retain this game’s dark/mint theme, art and gameplay.
