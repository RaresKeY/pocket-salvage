# v0.1.1 audio and compact UI review

VERDICT: APPROVE for the inspected Linux desktop source scope.

## Scope

Ready, running, paused and results in the playable scene, plus the HUD and audio labs. Hardware captures at 768×480, 854×480, 960×540, 1280×720 and 1920×1080. Keyboard and mouse paths; no gameplay balance changes.

## Findings and changes

- The source launcher forwarded video but no audio. A local image with libpulse0 and the exact desktop Pulse socket restores the real driver. Players explicitly select Stream playback for consistent runtime control.
- Two header rows and long footer copy reduced the yard at small sizes. A single header row, compact head/footer status and measured panel clearances increase the usable yard without stretching it.
- The start modal described a universal magnet. It now explains both heads, stands, ten pieces, four minutes and wrong-bin penalties.
- Music had only a shortcut and SFX had no control. Independent text-labeled toggles remain accessible above modals. Activating them while running releases UI focus so Space still controls the crane.
- Motor sample endpoints had a discontinuity. Generated loops now smooth that boundary; a small synthesized pause/resume click uses the same seeded generator.

## Verification

`./tests/check` passed in an isolated copy of the source through the shared runner. The physical scenario completed ten deliveries, wrong-bin recovery and a head swap in 170.05 simulated seconds. Final focus-return and audio-lab changes passed focused HUD and audio tests afterward.

`tools/capture_polish.gd -- --output res://.local/captures/SIZE` supplies matching four-state captures of the real scene. Invoked through headless Gamescope and the hardware-default managed runner with `--resolution SIZE --max-fps 60 --audio-driver Dummy`. Baseline was `cdd8a61`; source-copy before/after evidence is retained under ignored `.local/polish/`. All five sizes reported NVIDIA GeForce RTX 2080 Ti Compatibility rendering. No clipping or overlapping controls was found in the inspected states. Capture results are synthetic presentation fixtures, not new gameplay completion evidence.

`tests/audio_test.gd -- --require-pulse` ran in the audio-enabled managed container under headless Gamescope with the exact desktop Pulse socket. A bus capture upstream of muted Master produced non-silent frames independently for every effect, both motors and music. Decoding checks use Godot's decoder, including compressed imports; every cue is finite, non-silent and below full scale in the checked samples. The highest isolated captured peak was 0.674276. `HUD_TEST_OK`, `AUDIO_TEST_OK driver=PulseAudio` and `CHECKS_OK` were observed. Logs are local, not committed.

## Unverified

Subjective speaker listening, physical Windows execution, controller/touch support and localization expansion. Export checks and browser observations belong to the release record; source screenshots do not prove export behavior. Settings are session-only. New generated music was cancelled; the existing loop remains.

Export follow-up: the locally built v0.1.1 Linux executable started on RTX 2080 Ti; Firefox exercised the packaged Web controls with no console errors and verified actual audio samples before a muted destination. Windows remains unexecuted. See [build validation](../specs/builds.md). The first Linux screenshot attempt used a host ImageMagick build without X11 support and failed; that capture is not evidence. The successful later check is native startup/exit and renderer output; the screenshots above are source-scene captures.
