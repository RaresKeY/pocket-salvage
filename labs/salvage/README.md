# Playable salvage prototype

Run `labs/salvage/lab.tscn` or choose **Play prototype** in the main yard preview. Press **Start round** (or Enter). A/D or arrows move the trolley, W/S or arrows raise/lower the magnet, Space toggles pickup/release, P/Escape pauses, R restarts, and F2 returns to the scene preview. Losing window focus pauses the round.

Lower near a piece, enable the magnet, lift above the bin rims, move to its matching copper/rubber/steel bin and release. Six pieces, two minutes; correct +100, wrong −25 (minimum score zero). Clearing all pieces or reaching zero time ends the round. The arcade magnet can carry all three materials, including rubber; this is a provisional game rule, not a simulation of ferromagnetism.

This lab composes the independent crane suspension, sorting/round, HUD and layout modules. `payload.gd` adapts generic physics components to the prototype item fields. The authored rectangles, masses, timings and scoring are editable experimental choices rather than final game design. Art uses the stored 8× textures with runtime linear filtering.

`tests/salvage_test.gd` drives the crane through six real physics deliveries, checks carrying pause/resume, score, end/restart and timeout release. The top-pivoted magnet swings and tilts up to ±35°; cable tension and attached loads act on its rigid body. Cable art stays behind the magnet and hoist, with no reset during movement/reeling. Endpoint collisions and force attachments stay active; terrain-wrapping polygons and physical load feedback into the crane are not configured here. No controller/touch, shipping build or performance acceptance is claimed.
