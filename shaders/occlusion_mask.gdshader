shader_type canvas_item;
// Opaque mask pixels hide the target. Outside the mask rectangle stays visible.
uniform sampler2D occlusion_texture : filter_nearest, repeat_disable;
uniform bool mask_enabled = false;
uniform vec2 mask_size = vec2(1.0);
uniform vec2 mask_axis_x = vec2(1.0, 0.0);
uniform vec2 mask_axis_y = vec2(0.0, 1.0);
uniform vec2 mask_origin = vec2(0.0);
varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (mask_enabled) {
		vec2 local_position = mask_axis_x * world_position.x + mask_axis_y * world_position.y + mask_origin;
		vec2 mask_uv = local_position / mask_size + vec2(0.5);
		if (all(greaterThanEqual(mask_uv, vec2(0.0))) && all(lessThan(mask_uv, vec2(1.0)))) {
			COLOR.a *= 1.0 - texture(occlusion_texture, mask_uv).a;
		}
	}
}
