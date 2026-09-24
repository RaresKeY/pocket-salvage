# Sprite playground

Open **Sprite playground** from the default scaling lab, or run `labs/sprite_playground/lab.tscn` (F6 in the editor). The gallery uses all 48 non-mask PNGs from `assets/bitwright_8x/`; masks remain available separately. The original pixel-scaling lab remains the default project entry point.

Drag the washing machine in the right arena and release to toss it. Hold Q/E while grabbing to rotate it. Object size ranges from 1× to 4× the original dimensions, with linear filtering by default and a nearest comparison toggle. Reset restores its position and motion. The texture stays 192×224 in memory as its displayed size changes.

Physics remains active during the damped spring grab. The body itself stays at unit scale; sprite scale and an independently authored rectangular collision approximation change together. This is a lab object, not final scrap collision geometry or magnet gameplay. Gallery previews fit their cells uniformly without changing aspect ratio.

`./tests/check` checks all 75 source/output pairs and provenance, gallery count, floor collision, display/collision size, filter switching, viewport mouse grabbing/release and reset. `./labs/capture sprite_playground` performs background hardware-rendered captures through Gamescope and the shared runner.
