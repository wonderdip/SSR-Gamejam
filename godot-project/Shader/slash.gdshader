shader_type canvas_item;

uniform vec4 slash_color : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float arc_degrees : hint_range(10.0, 360.0) = 110.0;

uniform float radius : hint_range(0.1, 1.5) = 0.62;
uniform float thickness : hint_range(0.01, 0.5) = 0.16;

uniform float edge_width : hint_range(0.001, 0.2) = 0.035;
uniform float glow_width : hint_range(0.01, 0.5) = 0.15;

uniform float taper : hint_range(0.1, 5.0) = 1.8;
uniform float glow_strength : hint_range(0.0, 5.0) = 1.5;

uniform float streak_strength : hint_range(0.0, 1.0) = 0.5;
uniform float streak_width : hint_range(0.001, 0.2) = 0.035;

uniform float distortion : hint_range(0.0, 0.2) = 0.025;
uniform float noise_scale : hint_range(1.0, 30.0) = 8.0;

uniform float pixel_size : hint_range(0.001, 0.1) = 0.015;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);
}

float angle_difference(float a, float b) {
	return atan(sin(a - b), cos(a - b));
}

void fragment() {
	vec2 uv = UV;

	// Pixelate the UV slightly for a retro look.
	uv = floor(uv / pixel_size) * pixel_size;

	vec2 p = uv - vec2(0.5);

	float dist = length(p);
	float angle = atan(p.y, p.x);

	// ---------------------------------------------------------
	// ANGLE
	// ---------------------------------------------------------

	// Center the slash around the right side.
	float centered_angle = angle;

	float half_arc = radians(arc_degrees) * 0.5;

	float angle_distance = abs(
		angle_difference(centered_angle, 0.0)
	);

	// ---------------------------------------------------------
	// ARC MASK
	// ---------------------------------------------------------

	float arc_mask = 1.0 - smoothstep(
		half_arc,
		half_arc + 0.025,
		angle_distance
	);

	// ---------------------------------------------------------
	// SWEEP POSITION
	// ---------------------------------------------------------

	float normalized_angle =
		(angle + half_arc) / (half_arc * 2.0);

	normalized_angle = clamp(normalized_angle, 0.0, 1.0);

	float sweep = smoothstep(
		progress - 0.18,
		progress,
		normalized_angle
	);

	arc_mask *= sweep;

	// ---------------------------------------------------------
	// NOISE / DISTORTION
	// ---------------------------------------------------------

	float n = noise(
		p * noise_scale +
		vec2(TIME * 2.0, -TIME * 1.5)
	);

	float distorted_radius =
		radius + (n - 0.5) * distortion;

	// ---------------------------------------------------------
	// MAIN SLASH BODY
	// ---------------------------------------------------------

	float radius_difference =
		abs(dist - distorted_radius);

	float body = 1.0 - smoothstep(
		thickness,
		thickness + 0.025,
		radius_difference
	);

	body *= arc_mask;

	// ---------------------------------------------------------
	// TAPER
	// ---------------------------------------------------------

	float taper_start = smoothstep(
		0.0,
		0.25,
		normalized_angle
	);

	float taper_end = 1.0 - smoothstep(
		0.65,
		1.0,
		normalized_angle
	);

	float taper_mask =
		pow(taper_start * taper_end, taper);

	body *= taper_mask;

	// ---------------------------------------------------------
	// INNER WHITE EDGE
	// ---------------------------------------------------------

	float inner_radius =
		max(thickness - edge_width, 0.001);

	float inner_edge = 1.0 - smoothstep(
		inner_radius,
		inner_radius + 0.025,
		radius_difference
	);

	inner_edge *= arc_mask;
	inner_edge *= taper_mask;

	// ---------------------------------------------------------
	// OUTER GLOW
	// ---------------------------------------------------------

	float glow = 1.0 - smoothstep(
		thickness,
		thickness + glow_width,
		radius_difference
	);

	glow *= arc_mask;
	glow *= taper_mask;
	glow *= glow_strength;

	// ---------------------------------------------------------
	// SECONDARY STREAK
	// ---------------------------------------------------------

	float streak_radius =
		distorted_radius + thickness * 0.75;

	float streak_distance =
		abs(dist - streak_radius);

	float streak = 1.0 - smoothstep(
		streak_width,
		streak_width + 0.025,
		streak_distance
	);

	streak *= arc_mask;
	streak *= taper_mask;
	streak *= streak_strength;

	// ---------------------------------------------------------
	// LEADING EDGE
	// ---------------------------------------------------------

	float leading_edge = smoothstep(
		progress - 0.035,
		progress,
		normalized_angle
	);

	float edge_angle =
		abs(normalized_angle - progress);

	float strike_edge = 1.0 - smoothstep(
		0.0,
		0.08,
		edge_angle
	);

	strike_edge *= arc_mask;

	// ---------------------------------------------------------
	// FINAL COLOR
	// ---------------------------------------------------------

	vec3 color = vec3(0.0);

	color += glow_color.rgb * glow;
	color += slash_color.rgb * body;
	color = mix(
		color,
		edge_color.rgb,
		inner_edge
	);

	color += edge_color.rgb * strike_edge * 0.75;
	color += slash_color.rgb * streak;

	float alpha =
		max(
			max(body, glow),
			max(inner_edge, streak)
		);

	alpha = max(
		alpha,
		strike_edge * 0.75
	);

	COLOR = vec4(
		color,
		alpha * slash_color.a
	);
}