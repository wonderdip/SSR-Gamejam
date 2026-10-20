shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.5) = 1.3;
uniform float softness = 0.12;
uniform float aspect = 1.78;
uniform vec4 blood_color : source_color = vec4(0.45, 0.0, 0.02, 1.0);

void fragment() {
	vec2 uv = (UV - 0.5) * vec2(aspect, 1.0);
	float a = atan(uv.y, uv.x);
	// wobbly edge so it looks like pooling blood, not a clean circle
	float wobble = sin(a * 7.0 + TIME * 2.0) * 0.02 + sin(a * 13.0 - TIME * 3.0) * 0.01;
	float edge = smoothstep(radius + wobble, radius + wobble + softness, length(uv));
	COLOR = vec4(blood_color.rgb, edge);
}