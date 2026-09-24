# Rendering Effects

Store Godot shader sources and shared shader includes here when needed. Document supported renderers, parameters, and visual verification with the owning subsystem.

`occlusion_mask.gdshader` hides sprite pixels beneath an independent alpha mask. Its component API, same-canvas requirement and verification belong to [the physics subsystem](../specs/physics.md). It never changes collision geometry.
