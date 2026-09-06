shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 1.0) = 0.3; // how far the trail extends, in UV units
uniform int blur_samples : hint_range(1, 32) = 12;
uniform float blur_strength : hint_range(0.0, 1.0) = 0.7; // higher = trail fades out faster

const int MAX_SAMPLES = 32;

void fragment() {
	vec4 accum = texture(TEXTURE, UV);
	float total_weight = 1.0;

	for (int i = 1; i < MAX_SAMPLES; i++) {
		if (i >= blur_samples) {
			break;
		}

		float t = float(i) / float(blur_samples);
		// sample below the current UV — this reads as a trail left behind
		// something moving upward, since UV.y increases downward
		vec2 sample_uv = UV + vec2(0.0, t * blur_amount);

		if (sample_uv.y <= 1.0) {
			float weight = pow(1.0 - t, mix(1.0, 4.0, blur_strength));
			accum += texture(TEXTURE, sample_uv) * weight;
			total_weight += weight;
		}
	}

	COLOR = accum / total_weight;
}
