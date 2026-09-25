# Suspension experiments

## User design

Develop reusable subsystems with focused proving scenes, documenting implementation separately from intent. Current object scope remains reusable capabilities, with concrete magnet/scrap/bin definitions and collision conversion deferred.

## AI-inferred experiment

Compose the existing rope and caller-authored collision capabilities into a movable suspension endpoint and force attachment. Keep geometry, attachment selection and input outside that reusable component. A plain rectangle in the lab demonstrates lifting, swinging and release without choosing final game objects.

The attachment uses a damped spring with equal/opposite reactions on the magnet and load. The hoist remains motor-controlled. Handling, pickup rules, breakage and final geometry remain subject to playtesting.

## User handling correction

The user requested that the moving crane never reset its rope, that the cable remain a physical connection supporting the magnet, that the magnet rotate around a pivot with limited tilt, and that the cable draw behind both magnet and upper hoist.

## Implementation choices

Use a top-pivoted rigid-body endpoint and a massless tension-only constraint, preserving cable particle motion through normal movement/reeling. Start with a configurable ±35° tilt cap and modest native damping; remove the earlier per-frame horizontal velocity cancellation. Position the load mount below the magnet so forces can turn it. These numerical settings are proposed tuning, while continuous physical suspension and correct draw order are explicit user intent.

## User design: heads, stands and sound (2026-09-25)

From [jam polish](../prompts/source/jam-polish.md), Dale: the crane should have "a magnet head and also a gripper so you pick up thigs that cannot be picked up by magnet", with heads "you p[ut down and pick uhp"; "magnet wont pick up rubber"; the claw closed "to sonn", not "as you ge to he oiutem"; the crane "doesnt make a noise" when it moves down or along.

## AI-inferred design: heads, stands and sound

- Two heads (Claude): the magnet grips steel only; the claw grips copper and rubber. With no head fitted, the bare hook (the chain link sprite) grips nothing. Head rules, animations and sounds live in one table so another head is a data entry.
- Swapping (Claude): two tool stands at the left end, one holding the claw at the start. Lower the head onto the empty stand and press E to park it, then lower the bare hook onto the other stand and press E to fit that head. Parking and fetching as two steps keeps Dale's "put down and pick up" literal and makes a swap cost real time. E and the stand layout are provisional bindings.
- The magnet engages as soon as Space switches it on. The claw arms open ("Claw READY") and only shuts, with its sound, when it catches something, following Dale's feedback.
- Pickup grips the middle of whichever edge of a piece faces up, so tumbled scrap stays reachable; a head held over something it cannot grip says which head is needed.
- New art (Claude, drawn with Bitwright): a claw head with open, half and closed frames, and a tool stand. Exact requests are in [the image record](../prompts/image/scrapyard-bitwright.md).
- Motor sound (Claude): a low trolley rumble and a higher winch whine loop, each at a level that follows the actual travel or reel speed, so they fade in and out, stay silent at an end stop, and stop when the round is not running. See [audio](audio.md).
