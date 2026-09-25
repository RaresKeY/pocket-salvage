# Performance and audio resilience

## User design

RaresKeY, 2026-09-25: [exact requests](../prompts/source/performance-audio.md). Profile and optimize intermittent Web lag and audio crackling, including audio priority/threading where appropriate; profile native builds too. The reported platform is Firefox on Linux. Automated launches must stop producing annoying repeated audio.

## AI-inferred design

Use the shared Godot Performance Lab helpers in an isolated profiling checkout. Separate clean end-to-end frame timing from instrumented function attribution and deliberate 250 ms audio-stall tests. Keep automated visual runs in headless Gamescope and mute output downstream of browser audio probes; mute native Master. Record focus, refresh, GPU and host load, and qualify unmatched comparisons.

Use Web Audio Sample playback for the current non-positional WAV sounds; retain native Stream mixing. Let the platform schedule audio rather than adding GDScript audio threads or attempting browser/OS priority overrides. Avoid redundant stable loop-parameter updates. Keep single-threaded Web exports compatible with existing Pages hosting.

Optimize measured work: reuse cable ray-query resources and vector lengths; eliminate the second HUD refresh in every physics tick; skip presentation rebuilding when displayed data is unchanged while retaining the hurry pulse. Preserve the rope’s eight constraint passes and collision semantics, gameplay rules and visual content. Validate v0.1.5 locally before publishing through the existing release flow.

AI-inferred pacing choice: cap Web presentation at 60 FPS after the 165 Hz experiment showed missed high-refresh budgets and steadier intervals at 60. Keep native refresh uncapped. Callback wall times with this cap include engine pacing time and must not be reported as CPU execution cost.
