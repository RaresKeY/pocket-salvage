# Audio

Reviewed: 2026-09-25. Implementation revision: `53982f2` (source UI/wind pass; not in published v0.1.6).

## Ownership

`scripts/audio/sfx.gd` plays everything; `tools/audio/make_sfx.py` and `tools/audio/make_music.py` generate `assets/audio/*.wav` (16-bit mono, 22050 Hz, standard library only, seeded, so reruns reproduce the files). The generated sounds remain provisional. RaresKeY’s latest correction keeps the existing music and requests working playback instead of new music generation. A replacement WAV with the same name needs no code change.

## Player contract

`play(sound, volume_db = 0, pitch_jitter = 0)` loads `res://assets/audio/<sound>.wav` once and plays it on the next of 8 pooled voices, silently skipping a missing file. `set_loop(sound, level, pitch = 1, volume_db = -6)` runs a looping stream (loop end set from the stream length) at `level` 0 to 1; levels under 0.02 count as 0, the audible level eases toward the target at 6 per second from −40 dB up to `volume_db`, pitch follows `pitch * (0.85 + 0.15 * level)`, and a loop stops once faded out. `loop_level(sound)` returns the target. Every enabled effect request is appended to `played` (last 256) before playback. Under the Dummy audio driver (headless runs) nothing is played, because unmixed playbacks outlive the game and fail the check runner. Leaving the tree stops and clears all voices and loops.

## Sounds

Effects: `ui_click` (pause/resume), `start`, `magnet_on`, `magnet_off`, `claw_shut`, `claw_open`, `clank`, `pickup`, `land`, `correct`, `wrong`, `eject`, `tick`, `finish`, `thunder` (weather rumble and strike). Loops: `wind_loop` and `rain_loop` (weather, same seam correction), `trolley_loop` and `winch_loop` (one second, whole-hertz tones plus a short endpoint correction for the noise layer) and `music_yard`, a 32-second ambient loop in A minor (Am F C G pads, soft bass, sparse plucked arpeggio, note tails wrapped so it loops without a seam). `make_music.py` imports the tone and WAV helpers from `make_sfx.py`.

## Use in the salvage round

The lab starts `music_yard` at −17 dB from its first frame; M or the Music button toggles it. Heads name their grip and release sounds in `crane_heads.gd`. Motor levels are set from the actual trolley travel and cable reel per move, with the winch pitched up while raising, and silenced whenever the round is not running. Details of which events play which sounds are in [the integration spec](salvage_prototype.md).

## Verification

`tests/salvage_test.gd` loads every generated WAV as `AudioStreamWAV`, checks music plays from the start screen and mutes, checks the motor levels, and checks the round requested start, magnet, claw, clank, pickup, wrong, eject, correct and finish. `tests/audio_test.gd` now decodes every imported cue and optionally requires actual PulseAudio mixer output; details below.

## Playback controls and desktop launch

Voices and loops explicitly select browser-managed Sample playback on Web and Stream playback on native platforms. `effects_enabled` gates one-shots; disabling effects stops active voices and motors without changing music. Motor targets remain current while muted, so re-enabling follows real movement. `output_bus` may be set before readiness for isolated verification. Settings are scene-session-only, survive round restarts and are not saved across application launches. Web audio needs a browser gesture, supplied by Start.

`play.sh` prepares `localhost/pocket-salvage-audio:4.7` from the shared Godot image plus libpulse0, forwards only the exact desktop PulseAudio/PipeWire-Pulse socket, and explicitly selects PulseAudio. Missing sockets fail visibly. Import uses Dummy audio; import and play share the managed project lock with hardware GPU access. The runner/base image are unchanged. [Tooling provenance](../vendored/audio_launch.md). Exports use their normal platform driver and do not depend on this image.

The independent [audio lab](../labs/audio/lab.tscn) exposes every effect and loop. The standard suite decodes compressed imports and checks non-silent, unclipped samples and independent music/effects state. `tests/audio_test.gd -- --require-pulse` captures each effect and loop independently on a bus upstream of muted Master, keeping automation quiet. This proves real mixer output, not subjective speaker quality. See [review and commands](../docs/audio-ui-review.md).

Web voices and loops use browser-managed Sample playback, so already-started sounds are mixed by Web Audio independently of game-frame stalls. Native builds keep Stream playback and native driver mixing. The game uses no bus effects or procedural audio streams that require the Web streaming mixer. Browser priority is managed by the browser; no OS priority or custom audio thread is introduced.

Stable loop volume/pitch values do not resend unchanged parameters to the browser audio graph. Fades and pitch changes retain their existing easing.

Performance and underrun evidence, including intentionally silent stress tests, is recorded in [the Firefox/Linux review](../docs/performance-review.md).

Pause-menu Music/SFX sliders call `set_volumes(music, effects)` with clamped 0–1 values. Levels apply additively in dB to existing voice/loop mix levels (0.5 is about −6.02dB); zero stops playback in that category. SFX includes weather and motors. Mute retains the chosen levels. Values persist across round restarts in the scene session, not across app launches. Stable volume setters remain suppressed in the loop update.
