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
