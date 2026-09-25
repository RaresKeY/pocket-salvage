# Wind and square pixel UI review

Reviewed: 2026-09-25. Implementation revision: `53982f2`; published in v0.1.7 after its release version bump.

VERDICT: APPROVE for the inspected source UI and Linux/Firefox export scope.

## Scope

The playable HUD, ready/pause/results views, local Developer options, weather wind/dust and existing rain, session audio controls and export typography. Supper Guard’s shared theme and UI progression spec informed aligned groups and separation; its assets/source were not copied.

## Findings and changes

- Continuous bright streak/dust particles dominated the yard. Wind now uses three slow curved antialiased ribbons with tip/lifetime/edge fades; dust is seven varied dark-brown particles per sparse raised burst. Rain and wind forces are unchanged.
- Rounded panels and loose status placement were inconsistent with the requested compact UI. A shared square theme groups counters/actions and moves head/weather status to the top, with thin dividers and compact secondary copy.
- Typography depended on Godot’s fallback font. Tiny5 is bundled with a pinned source/hash, complete OFL and notices. HUD, menus, bin labels and score popups share it; every platform preset packages the license.
- Music/SFX controls only muted. Pause now offers independent sliders, preserving chosen levels through mute and round restarts. They affect one-shots, motors/weather loops and music without changing authored mix ratios.
- Controller buttons previously bypassed all menu navigation. Explicit pause D-pad navigation reaches sliders, changes them by 5%, and keeps A activation and B/Start resume distinct. Running controls remain intact.

## Verification

The managed `tests/run_checks.py` suite passed in an isolated source copy, including the deterministic salvage round and weather scenarios. Updated weather checks cover direction, edge fading, bounded trails and slow raised dust with size/color variation. Audio tests cover gain/clamping/mute retention; HUD checks cover bundled font, square borders and slider signals. After the final controller routing change, focused HUD, input, Developer-overlay and navigation tests passed again. Real dispatched D-pad inputs separately verified changes to both actual SFX/music levels. Eight release-contract tests passed.

Hardware Gamescope captures on NVIDIA RTX 2080 Ti inspected 1920×1080, 1280×720, 960×540, 854×480, 640×360 and 390×844. Before/after running and paused scenes are comparable; the first capture script mislabeled running screenshots as ready, so those are not ready-state baseline evidence. Final ready, running, paused, expanded Developer and finished captures use actual transitions and check action/diagnostic containment. Automated runs used Dummy audio or browser probes upstream of a muted output.

Linux, Windows and Web exports succeeded; each packed the Tiny5 font resource, full OFL and notices. The exported Linux binary started/exited on hardware with Dummy audio and no engine errors. Firefox loaded the actual Web export, displayed Tiny5 and square controls, and used real keyboard focus/Home/End inputs to set music and SFX to zero and restore them. An analyser before a muted destination measured exactly zero at either zero setting, nonzero restored output and no game-console errors. These exports validate packaging and runtime behavior, not a new published version.

## Limits

Windows was exported but not executed. Controller/touch checks are simulated, not physical-device playtests. Volume settings remain scene-session-only. No new performance benchmark or subjective listening claim is made. Weather balance is unchanged. The user subsequently requested deployment to both sites; v0.1.7 contains this implementation.

Ignored evidence: `.local/ui-wind/` contains baseline/final screenshots, browser mixer evidence and managed logs. Temporary export payloads and the isolated source copy are removed after verification.

The upstream OFL file is preserved byte-for-byte, including its existing trailing space on line 21. Application-source whitespace checks pass; that vendor-license whitespace is intentional provenance preservation.

## Published verification

v0.1.7 (`39312c3`) is deployed to Firebase and GitHub Pages. Every hosted payload file was hash-compared with the verified GitHub release on both hosts. The actual Firebase Firefox run repeated keyboard slider-zero/restore, mute and movement checks with nonzero restored audio, zero output at zero settings and no console errors; diagnostics remained hidden. See the [delivery record](../specs/builds.md).
