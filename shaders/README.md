# Rendering Effects

Store Godot shader sources and shared shader includes here when needed. Document supported renderers, parameters, and visual verification with the owning subsystem.

`occlusion_mask.gdshader` hides sprite pixels beneath an independent alpha mask. Its component API, same-canvas requirement and verification belong to [the physics subsystem](../specs/physics.md). It never changes collision geometry.

Blood Moon uses `blood_moon_bulbs.gdshader` for lens-only red emission and power dimming, and `blood_moon_grade.gdshader` for the yard’s 5% screen wash and edge tint. Parameters, ownership and GPU verification are in [levels](../specs/levels.md). Both use the Compatibility renderer and preserve source alpha.
