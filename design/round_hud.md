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

AI-inferred performance follow-up to [RaresKeY’s profiling request](../prompts/source/performance-audio.md): present one current HUD snapshot per physics tick and rebuild presentation only when displayed data changes; preserve the hurry pulse and immediate interaction feedback.

## Local developer controls

### User design

RaresKeY, 2026-09-25: [exact directive](../prompts/source/local-developer-options.md). Add pause-menu Developer options for hitboxes and masks locally, and report on absent audio sliders.

### AI-inferred design

Interpret local-only as native source runs using the editor binary, excluding Web and standalone exports; the follow-up explicitly authorizes rebasing and pushing the source change, while retaining the local-run feature gate. Default-off toggles persist across round restarts within a scene. Put them under a collapsed Developer options button. Green physical shapes and blue sensors are distinct from pink reference art masks and orange active occlusion masks. Never modify physics or mask materials; stop overlay processing when disabled. Audio sliders remain deferred pending direction; the recorded audio design currently specifies toggles.

## Square pixel UI pass

### User design

RaresKeY, 2026-09-25: [exact request](../prompts/source/wind-ui-polish.md) asks for Supper Guard-like compact separation, square presentation, top-aligned information and a supplied pixel font. The earlier [audio-slider question](../prompts/source/local-developer-options.md) identifies missing volume controls.

### AI-inferred design

Borrow Supper Guard’s shared theme, restrained separators and aligned information groups, keeping this yard’s dark palette. Use square 1px borders, fixed counter order, separate action/status groups and Tiny5 under OFL. Add session-only Music/SFX sliders to Pause alongside existing mute controls. On local runs, opening Developer options replaces those slider rows so Resume and diagnostics fit short screens.

AI-inferred accessibility: pause D-pad up/down navigates controls, left/right adjusts volume in 5% steps, A activates the selected button, and B/Start resumes. Keyboard sliders retain standard focus/arrow/Home/End controls.

## Mobile overlay, 2026-09-25

### User design

RaresKeY requested [rounded analog controls, diagonal left actions and fullscreen](../prompts/source/mobile-overlay.md), over the playable area while preserving aspect ratio.

### AI-inferred design

Keep the square main HUD. Move mobile feedback into the header, remove the reserved touch column/footer, reserve 60px for fullscreen, and reduce counter/action text at narrow widths to preserve clearance. Thumb controls use translucent circles and smooth generated pale-gray icons; menu states hide them.
