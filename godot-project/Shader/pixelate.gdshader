shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 128.0) = 1.0;

void fragment() {
	vec2 texture_size = vec2(textureSize(TEXTURE, 0));
	vec2 grid = pixel_size / texture_size;

	// snap the UV to the center of its grid cell before sampling,
	// so every texel within a cell reads the same color
	vec2 pixelated_uv = (floor(UV / grid) + 0.5) * grid;

	COLOR = texture(TEXTURE, pixelated_uv);
}
