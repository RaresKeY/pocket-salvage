# Audio

## User design

2026-09-25 ([jam polish](../prompts/source/jam-polish.md)): Dale approved the AI's proposal to add sound effects as part of "yes do it all"; asked for noise when the crane moves ("when the machine moves down it doesnt make a noise or when moving"); and asked for "some bacjkgriound music also soemethign sublee". RaresKeY subsequently asked to repair existing music/SFX and cancelled new music generation; [exact correction](../prompts/source/audio-ui-release.md).

Performance follow-up (RaresKeY, 2026-09-25): [exact request](../prompts/source/performance-audio.md) asks to profile Web/native lag and prevent audio crackling during stalls, using priorities or threads as needed. This is explicit user direction.

RaresKeY, 2026-09-25: the [launcher clarification](../prompts/source/wind-motes-launcher.md) explicitly selects current local files without fetching.

## AI-inferred design

Everything currently in `assets/audio/` is an **AI-generated placeholder** (Claude), synthesised by seeded standard-library Python scripts in `tools/audio/`, so any sound can be edited and regenerated identically. Keep existing music for this release; future replacements remain a separate decision.

- One-shots: start, magnet on and off, claw shut and open, pickup, landing thud (louder for heavy scrap), correct chime, wrong buzz, the throw-back, a tick each second in the last 10, finish, and a clank when a head is parked or fitted.
- Motor loops: `trolley_loop` and `winch_loop` are one-second loops whose frequencies complete whole cycles, with a short boundary correction for the noise layer. Their level follows the crane's real movement each frame; the winch pitches up when raising.
- Music: `music_yard`, a 32-second loop in A minor at 90 BPM with slow pad chords (Am, F, C, G), a soft bass and a sparse plucked arpeggio. Note tails wrap round the loop point so it has no seam. It plays quietly from the start screen onwards; M mutes it.
- Headless test runs record which sounds would play instead of playing them, because the dummy audio driver never mixes and its playbacks would outlive the test.

Open: final music, final effects, mix levels and whether to persist the session-only Music/SFX volume and mute settings across launches. See [the salvage integration spec](../specs/salvage_prototype.md).

AI-inferred v0.1.1 repair: explicit streamed playback, exact desktop audio socket forwarding, separate on/off controls, a quiet synthesized pause/resume click, and an independent audio lab/mixer test. No new music prompt or track is produced.


AI-inferred implementation: use browser-managed Sample playback for Web and retain the native Stream mixer. Current sounds need none of the unsupported Sample bus effects. This separates already-playing sound from game-frame progress without adding cross-origin isolation requirements to Pages. Priorities remain owned by the platform.

Launcher refinement: resolve symlinks to the owning checkout, print the local revision/dirty state, retain mandatory import under the managed lock, and launch the configured project main scene. The container remains only the engine/audio runtime; it never supplies cached game source. No fetch, pull, reset or exported-package selection occurs.

## Soft rain remake, 2026-09-25

### User design

RaresKeY asks for non-harsh rain with slight, normal and violent strengths ([exact request](../prompts/source/lightning-rain.md)).

### AI-inferred design

Replace the one-second white-noise/square-modulated rain with three eight-second seeded rain beds. Use three low-pass stages at 700/950/1200Hz, slow smooth amplitude variation and corrected loop seams; no unfiltered hiss or sharp taps. Source RMS levels are 0.035/0.055/0.075, mixed at −22/−19/−16dB respectively. Retain the normal `rain_loop` name; add `rain_slight_loop` and `rain_violent_loop`. These are synthesized soft rain washes, not field recordings. Existing music, thunder and wind audio are unchanged.
