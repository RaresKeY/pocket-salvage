# Firefox/Linux performance and audio review

Reviewed: 2026-09-25. Implementation: `07f1974` (v0.1.5); baseline `cb0993d`, whose playable payload is v0.1.4 / `6488a44`.

## Scope and method

The reported problem was intermittent lag and crackling in Firefox on Linux. The workstation display runs at 165 Hz. Tests used Firefox 156.0.1, Godot 4.7, 1280×720 at DPR 1, and off-screen Gamescope at 60 and 165 Hz. Native logs identified NVIDIA RTX 2080 Ti; Firefox exposes a privacy-masked NVIDIA renderer. The browser was visible but reported `document.hasFocus() == false` in all these runs; actual keyboard actions still drove the running game. Results describe this controlled off-screen condition, not every desktop/browser/device.

The shared Godot Performance Lab provided disabled-by-default function/monitor probes in an isolated checkout, the Firefox BiDi client and frame preload, native-log parsing/comparison, and host/GPU sampling. Probes were not shipped. Native attribution used exported release binaries with probes and a fixed movement/reeling scenario. Clean Web exports used identical start/warm-up and eight 1.8-second keyboard holds, followed by a separate audio stress phase. Initial loading was excluded.

Audio was measured by a test-only AudioWorklet upstream of a muted destination. It counts 128-frame blocks with peak amplitude below 1e-8 at 48 kHz, and verifies nonzero signal is actually present. Five deliberate 250 ms main-thread stalls test continuity separately from ordinary play. Native profiling was made silent by muting Master after the user reported the initial audible run; browser tests remain muted downstream of their probe. Temporary processes have bounded scenarios and are terminated after collection.

## Findings and changes

1. **Web audio depended on game-frame progress.** Every player explicitly used Stream playback in a single-threaded Web export. Under busy ordinary play, the repeated baseline accumulated 73 silent blocks (about 195 ms). The separate five-stall test accumulated 483 silent blocks (about 1.29 s). The optimized clean export recorded **zero silent blocks in both phases**, with nonzero signal verified. The capped instrumented run also recorded zero. This is measured dropout evidence, not a claim that every possible audible artifact is eliminated.
2. **Cable simulation was the largest measured script hot path.** `rope_solver.gd:simulate` and the surrounding suspension tick dominated attribution. `rope_2d.gd:_sweep` previously allocated a new physics query and reacquired the direct-space interface for every particle sweep. The query is now reused and its mask/exclusions refreshed once per step. Segment length is calculated once for constraint correction. Particle count, eight solver passes, all collision sweeps and physical behavior remain intact.
3. **HUD work was duplicated.** `round_state.tick()` emitted a change that refreshed the HUD, and the caller refreshed it again in the same tick. The caller now expires feedback before ticking and uses one change-driven refresh. `round_hud.gd:present` compares displayed snapshots with the timer rounded to seconds, skipping unchanged labels/buttons/theme operations while still updating the hurry pulse.
4. **Steady audio parameters were repeatedly sent to Web Audio.** Unchanged loop gain and settled pitch no longer issue redundant setters; existing fades and pitch easing remain.
5. **The uncapped Web game chased high refresh.** At 165 Hz the clean baseline averaged 7.28 ms inside a callback, exceeding the roughly 6.06 ms refresh budget. A busier repeat averaged 10.89 ms. Web presentation is now capped at 60 FPS; native builds keep their platform/VSync behavior. Physics remains 60 Hz and interpolated. Godot pacing time is included in capped callback wall time, so that number is not CPU execution cost.

## Measurements and limits

The native attribution pair, excluding five warm-up windows, measured cable simulation at 1.473 → 0.762 ms per process frame and HUD presentation at 0.242 → 0.027 ms per frame. Both sustained 60 FPS. Frame-interval p99 was 19.23 → 18.27 ms. Host/GPU load differed materially between runs, so the timing deltas are **directional**, not isolated percentage-speedup guarantees. The removal of per-ray resource allocation and duplicate HUD updates is independently established by the implementation and regression checks.

At 165 Hz, the busy clean Web baseline had callback mean 10.89 ms, interval p95 24 ms and p99 33.74 ms. The uncapped optimized clean export measured 7.53 ms, p95 20 ms and p99 33 ms; occasional long frames remained. Host CPU load also differed (about 83% vs 78% over the sampled runs), so this is directional end-to-end evidence. The 60 FPS instrumented trial measured interval p95 19 ms and p99 24 ms, with the engine monitor consistently reporting 60 FPS. Its callback wall time includes pacing. No GPU-bound or universal performance claim follows from these results.

The full engine suite passed, including the ten-piece/head-swap physics playthrough in 170.05 simulated seconds. Regression checks cover ray endpoints and changed masks/exclusions, within-second score updates, continued hurry animation, and platform audio-player selection. Eight release-contract tests passed. Clean Linux/Web exports matched byte for byte across two independent snapshots.

The final clean Web candidate at 165 Hz measured mean frame interval 16.67 ms, p95 18 ms and p99 22 ms (maximum 28 ms). Both audio phases had zero silent blocks and verified nonzero signal; the browser console had no errors. Independent music/mute/SFX/restore and start/pause/restart checks passed. This local candidate was built from `36d4ffa`; rebasing onto Dale’s new weather design and directive corrections produced `07f1974` with identical runtime/build sources.

The final instrumented native 165 Hz run measured interval p50 6.05 ms, p95 9.80 ms and p99 12.25 ms on the NVIDIA RTX 2080 Ti. It is an absolute result under shared host load, not a matched high-refresh speedup claim. Its probe-driven shutdown reported four leaked ObjectDB instances and two resources still in use; these teardown diagnostics are retained in the log, not counted as a clean shipping-runtime exit.

## Audio architecture decision

Browser-managed Sample playback mixes already-started WAV sounds independently of the main game frame. Native platforms retain Stream playback through their normal driver mixer. There is no custom GDScript audio thread, OS-priority change or cross-origin-isolation requirement. The current game does not use bus effects or procedural streams that need Web Stream playback. Sample limitations are documented by [Godot AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html) and [Web export audio guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

A newly requested sound or motor-parameter update still waits for the game frame to execute; already-playing audio continues. Browser/OS suspension or device underruns can still interrupt output. Windows was not profiled on Windows, and subjective listening was intentionally omitted from silent automated checks.

Local evidence and orchestration are under ignored `.local/perf/`: browser reports and host samples, exported-native logs, parsed comparisons, `browser_profile.py`, `audio_probe.js`, `instrument.py` and `native.sh`. The temporary profiling checkout and its generated exports were removed after measurement; the shipped source contains no probes. Source specs and design record the retained behavior; generated export packages are removed after verified delivery.

## Delivery

[Release workflow 36176275599](https://github.com/RaresKeY/pocket-salvage/actions/runs/36176275599) passed tests, repeated Windows/Linux/Web exports, verified downloaded release assets and live Pages file hashes. [v0.1.5](https://github.com/RaresKeY/pocket-salvage/releases/tag/v0.1.5) and [the playable site](https://rareskey.github.io/pocket-salvage/) identify source `07f1974`. Native PulseAudio mixer verification passed for every cue and loop with Master muted.

The public HTTPS build passed a fresh silent Firefox run: no game-console errors, nonzero audio and zero silent blocks in both ordinary and deliberate-stall phases. At the same 165 Hz off-screen setting, live frame intervals averaged 16.70 ms, with p95 18 ms, p99 26 ms and maximum 49 ms (four intervals above 33.33 ms). Occasional frame spikes remain under shared host load; continuous measured audio does not imply perfectly uniform rendering. Local candidate outputs were removed after remote verification; measurement logs and its manifest remain ignored.
