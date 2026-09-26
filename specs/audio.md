# Audio

Reviewed: 2026-09-26. Implementation: reward-audio/v0.1.9 preparation in this commit, based on `95f7797`.

## Ownership

`scripts/audio/sfx.gd` plays everything; `tools/audio/make_sfx.py`, `tools/audio/make_rain.py`, `tools/audio/make_wind.py` and `tools/audio/make_music.py` generate `assets/audio/*.wav` (16-bit mono, 22050 Hz, standard library only, seeded, so reruns reproduce the files). The generated sounds remain provisional. RaresKeY’s latest correction keeps the existing music and requests working playback instead of new music generation. A replacement WAV with the same name needs no code change.

## Player contract

`play(sound, volume_db = 0, pitch_jitter = 0)` loads `res://assets/audio/<sound>.wav` once and plays it on the next of 8 pooled voices, silently skipping a missing file. `set_loop(sound, level, pitch = 1, volume_db = -6)` runs a looping stream (loop end set from the stream length) at `level` 0 to 1; levels under 0.02 count as 0, the audible level eases toward the target at 6 per second from −40 dB up to `volume_db`, pitch follows `pitch * (0.85 + 0.15 * level)`, and a loop stops once faded out. `loop_level(sound)` returns the target. Every enabled effect request is appended to `played` (last 256) before playback. Under the Dummy audio driver (headless runs) nothing is played, because unmixed playbacks outlive the game and fail the check runner. Leaving the tree stops and clears all voices and loops.

## Sounds

Effects: `ui_click` (pause/resume), `start`, `magnet_on`, `magnet_off`, `claw_shut`, `claw_open`, `clank`, `pickup`, `land`, `correct`, `wrong`, `eject`, `tick`, `finish`, `thunder` (weather rumble and strike), `crackle`, `power_down` and `power_up` (Electric Storm blackouts). Loops: a 24-second soft `wind_loop`, three eight-second rain strengths (`rain_slight_loop`, normal `rain_loop`, `rain_violent_loop`), one-second `trolley_loop`, `winch_loop` and `twister_loop` (Level 5 twister roar; whole-hertz tones plus a short endpoint correction for the noise layer), and `music_yard`, a 32-second ambient loop in A minor (Am F C G pads, soft bass, sparse plucked arpeggio, note tails wrapped so it loops without a seam). `make_music.py` imports the tone and WAV helpers from `make_sfx.py`.

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

`play.sh` resolves its own symlinks, prints checkout/revision plus a local-changes marker, and launches `project.godot`’s current main scene after successful import. It binds current local source and never fetches/pulls or selects a release package. `tests/test_launcher.py` verifies changed local input across launches, symlink resolution, argument forwarding, no Git network operations, and no play after failed import using silent process stubs.

Launcher validation: shell syntax and the local-launch stub regression passed; it is registered in the full suite. Existing native audio forwarding is unchanged; automated visual runs use Dummy audio.

Rain masters are eight-second seeded beds from `make_rain.py`: three cascaded low-pass stages (700/950/1200Hz), smooth periodic amplitude variation, RMS 0.035/0.055/0.075 and corrected identical endpoints. Weather selects by rain rate (<100 / <200 / ≥200) and mixes at −22/−19/−16dB. No raw white-noise layer or square modulation remains in rain. `make_sfx.py` regenerates these recipes too; running `make_rain.py` changes only rain. Audio lab buttons expose all three. `tests/test_rain_audio.py` checks master/recipe identity, tier ordering, peak headroom, endpoint continuity and a bounded high-frequency difference measure; engine audio tests decode and optionally capture all tiers.

Validation (2026-09-25): seeded masters reproduced exactly; normalized sample-difference RMS was 0.116/0.159/0.201 for slight/normal/violent, with no clipping and identical endpoints. Full managed Godot suite passed after rebasing onto the latest skyline change (`826efb6`); silent PulseAudio capture independently confirmed nonzero output for all three loops (`AUDIO_TEST_OK driver=PulseAudio`). This verifies playback and signal bounds, not a subjective speaker-listening assessment. Evidence: `.local/rain-flicker-review/`.

Wind is a seeded 24-second filtered noise bed from `make_wind.py`, also regenerated by `make_sfx.py`. Three low-pass stages vary smoothly between 210–650Hz; a 65Hz high-pass suppresses deep rumble. Slow overlapping swells vary loudness and texture without tonal oscillators or rapid tremolo. Source RMS is 0.045 with corrected identical endpoints. The existing weather-driven level and −12dB mix remain. `tests/test_wind_audio.py` checks duration, quiet RMS, high-frequency suppression, headroom, seam continuity, gentle variation and recipe/master identity.

Wind validation (2026-09-26): regression rejects the previous one-second master; the replacement reproduces exactly, measures RMS 0.045 and normalized sample-difference RMS 0.093, and has a 4.18 ratio between loudest and quietest one-second windows. Full managed Godot 4.7 suite passed (`CHECKS_OK`) in an isolated source copy because the live game held the checkout lock. Imported audio decoding passed with Dummy audio; no speaker-listening assessment is claimed.

Correct-delivery reward playback uses −3dB in the salvage round (previously 0dB), before the SFX slider gain. The generated cue retains its existing pitch, duration and waveform.

Reward balance validation (2026-09-26): full managed Godot 4.7 suite passed (`CHECKS_OK`), including audio decode/mute/volume checks and correct-delivery playback requests. Eight release-contract tests passed. The −3dB adjustment is a mix choice, not a subjective listening measurement.

`Sfx.MUSIC` names the music loop, the one loop that follows the music volume. The generators share `seal_loop`, `normalise` and `lowpass` from `make_sfx.py`; `make_rain.generate()` and `make_wind.generate()` return how many files they wrote. Regenerating after the 2026-09-26 tidy produced byte-identical WAVs.
