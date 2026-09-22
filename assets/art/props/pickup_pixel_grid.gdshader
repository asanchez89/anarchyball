shader_type canvas_item;

uniform vec2 source_origin = vec2(0.0);
uniform vec2 source_extent = vec2(1.0);
uniform vec2 logical_size = vec2(28.0);
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 local_uv = clamp((UV - source_origin) / source_extent, vec2(0.0), vec2(0.99999));
	vec2 cell_uv = (floor(local_uv * logical_size) + vec2(0.5)) / logical_size;
	COLOR = texture(TEXTURE, source_origin + cell_uv * source_extent) * sprite_tint;
}
