shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float core_brightness : hint_range(0.0, 8.0) = 2.5;
uniform float halo_size : hint_range(0.0, 8.0) = 2.5;      // in texels
uniform float halo_intensity : hint_range(0.0, 4.0) = 1.2;
uniform float flicker_speed = 40.0;
uniform float flicker_amount : hint_range(0.0, 1.0) = 0.25;

varying vec4 mod_color;
varying float phase;

void vertex() {
	mod_color = COLOR;  // sprite.modulate, so fade_out keeps working
	phase = MODEL_MATRIX[3].x * 0.13 + MODEL_MATRIX[3].y * 0.17;  // desyncs each bolt
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * halo_size;

	// Cheap blur of the alpha channel: two rings of 8 samples
	float halo = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * TAU / 8.0;
		vec2 dir = vec2(cos(a), sin(a));
		halo += texture(TEXTURE, UV + dir * px).a;
		halo += texture(TEXTURE, UV + dir * px * 2.0).a * 0.5;
	}
	halo /= 12.0;

	float flick = 1.0 - flicker_amount * (0.5 + 0.5 * sin(TIME * flicker_speed + phase));

	vec3 core = tex.rgb * core_brightness * tex.a;
	vec3 aura = glow_color.rgb * halo * halo_intensity * (1.0 - tex.a);

	COLOR = vec4((core + aura) * flick * mod_color.rgb, mod_color.a);
}