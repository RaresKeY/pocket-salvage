shader_type canvas_item;
// Pixel regions plus lens-color selection preserve metal housings and poles.
uniform bool beacon = false;
uniform vec4 tint : source_color = vec4(1.0, 0.32, 0.27, 1.0);
uniform float power : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 source = COLOR;
    vec2 pixel = UV * (beacon ? vec2(8.0) : vec2(20.0, 56.0));
    float lens;
    if (beacon) {
        lens = (pixel.y < 4.0 && source.r > source.b * 1.5) ? 1.0 : 0.0;
    } else {
        bool row = pixel.y >= 6.0 && pixel.y < 10.0;
        bool column = pixel.x < 4.0 || (pixel.x >= 5.0 && pixel.x < 9.0)
            || (pixel.x >= 11.0 && pixel.x < 15.0) || pixel.x >= 16.0;
        bool glass = source.b > source.r + 0.08 || min(source.r, min(source.g, source.b)) > 0.95;
        lens = row && column && glass ? 1.0 : 0.0;
    }
    float brightness = max(source.r, max(source.g, source.b));
    vec3 lit = brightness * tint.rgb * mix(0.08, 1.0, power);
    COLOR = vec4(mix(source.rgb, lit, lens), source.a);
}
