shader_type canvas_item;

// -- Wave (the "sway") --------------------------------------------------
group_uniforms wave;
uniform float wave_amplitude : hint_range(0.0, 0.05) = 0.012;
uniform float wave_frequency : hint_range(0.0, 50.0) = 12.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;

// -- Blur (samples taken along the wobble path) --------------------------
group_uniforms blur;
uniform int blur_samples : hint_range(1, 16) = 8;
uniform float blur_amount : hint_range(0.0, 0.05) = 0.015;

// -- Misc -----------------------------------------------------------------
group_uniforms misc;
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;

const int MAX_SAMPLES = 16;

void fragment() {
	vec2 uv = UV;
	float t_time = TIME * time_scale;

	vec4 accum = vec4(0.0);
	float weight_sum = 0.0;

	for (int i = 0; i < MAX_SAMPLES; i++) {
		if (i >= blur_samples) {
			break;
		}

		float t = float(i) / float(max(blur_samples - 1, 1));
		float phase = t_time * wave_speed + t * TAU;

		// sway distortion, based on position so it ripples across the sprite
		vec2 sway = vec2(
			sin(uv.y * wave_frequency + phase) * wave_amplitude,
			cos(uv.x * wave_frequency + phase) * wave_amplitude
		);

		// blur offset walks around a small circle in step with the sway,
		// so the samples smear along the same wobble instead of a straight line
		vec2 blur_offset = vec2(cos(phase), sin(phase)) * blur_amount * t;

		vec2 sample_uv = clamp(uv + sway + blur_offset, vec2(0.0), vec2(1.0));

		float weight = 1.0 - t * 0.3; // slight falloff so center samples dominate
		accum += texture(TEXTURE, sample_uv) * weight;
		weight_sum += weight;
	}

	COLOR = accum / weight_sum;
}
