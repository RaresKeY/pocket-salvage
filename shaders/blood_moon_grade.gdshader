shader_type canvas_item;
// Applied to the yard's viewport container, leaving menus/HUD readable.
uniform vec4 taint : source_color = vec4(0.65, 0.06, 0.09, 1.0);
uniform float wash : hint_range(0.0, 0.2) = 0.05;
uniform float edge_tint : hint_range(0.0, 0.2) = 0.05;

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    vec3 right = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb;
    vec3 above = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb;
    float edge = clamp((length(source.rgb - right) + length(source.rgb - above)) * 3.0, 0.0, 1.0);
    vec3 graded = mix(source.rgb, taint.rgb, wash);
    graded = mix(graded, vec3(1.0, 0.28, 0.22), edge * edge_tint);
    COLOR = vec4(graded, source.a);
}
