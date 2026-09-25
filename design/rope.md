# Rope design

## User design

Pocket Salvage uses a magnetic crane to collect scrap and sort it before a timer expires. First copy rope code from White Approach and Plug & Prosper, then extract the more refined foundation into a reusable module with a showcase lab. Commit and push that milestone before implementing object/magnet physics.

## AI-inferred design

Begin with 2D: both source games already supply relevant 2D physics. Use White Approach's static terrain wrapping and slack/tension solver plus Plug & Prosper's refined jacket rendering. Treat “submodule” as an in-repository component, matching the art specs module. Avoid a new repository or clone dependency. The lab's mint cable, dark backdrop and pillar are diagnostic styling, not approved final art direction.

The game will own crane controls, load motion, magnet interaction, sorting and time. The rope supplies reusable geometry, constraints and collision queries, with no knowledge of score or round state. Current limits live in [the rope spec](../specs/rope.md).

AI-inferred performance follow-up to [RaresKeY’s profiling request](../prompts/source/performance-audio.md): remove repeated ray-query allocation and duplicate vector-length work while preserving solver iterations, collisions and cable behavior.
