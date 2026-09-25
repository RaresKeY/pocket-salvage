# Audio

Reviewed: 2026-09-25. Implementation revision: `cdd8a61`.

## Ownership

`scripts/audio/sfx.gd` plays everything; `tools/audio/make_sfx.py` and `tools/audio/make_music.py` generate `assets/audio/*.wav` (16-bit mono, 22050 Hz, standard library only, seeded, so reruns reproduce the files). The generated sounds are placeholders: RaresKeY intends to supply music and effects, and a replacement WAV with the same name needs no code change.

## Player contract

`play(sound, volume_db = 0, pitch_jitter = 0)` loads `res://assets/audio/<sound>.wav` once and plays it on the next of 8 pooled voices, silently skipping a missing file. `set_loop(sound, level, pitch = 1, volume_db = -6)` runs a looping stream (loop end set from the stream length) at `level` 0 to 1; levels under 0.02 count as 0, the audible level eases toward the target at 6 per second from −40 dB up to `volume_db`, pitch follows `pitch * (0.85 + 0.15 * level)`, and a loop stops once faded out. `loop_level(sound)` returns the target. Every requested sound is appended to `played` (last 256) before playback. Under the Dummy audio driver (headless runs) nothing is played, because unmixed playbacks outlive the game and fail the check runner. Leaving the tree stops and clears all voices and loops.

## Sounds

Effects: `start`, `magnet_on`, `magnet_off`, `claw_shut`, `claw_open`, `clank`, `pickup`, `land`, `correct`, `wrong`, `eject`, `tick`, `finish`. Loops: `trolley_loop` and `winch_loop` (one second, whole-hertz tones so the seam is silent) and `music_yard`, a 32-second ambient loop in A minor (Am F C G pads, soft bass, sparse plucked arpeggio, note tails wrapped so it loops without a seam). `make_music.py` imports the tone and WAV helpers from `make_sfx.py`.

## Use in the salvage round

The lab starts `music_yard` at −17 dB from its first frame; M toggles it. Heads name their grip and release sounds in `crane_heads.gd`. Motor levels are set from the actual trolley travel and cable reel per move, with the winch pitched up while raising, and silenced whenever the round is not running. Details of which events play which sounds are in [the integration spec](salvage_prototype.md).

## Verification

`tests/salvage_test.gd` loads every generated WAV as `AudioStreamWAV`, checks music plays from the start screen and mutes, checks the motor levels, and checks the round requested start, magnet, claw, clank, pickup, wrong, eject, correct and finish. No check listens to audio output.
