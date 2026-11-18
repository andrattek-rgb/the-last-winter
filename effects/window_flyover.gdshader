shader_type canvas_item;
render_mode unshaded;

uniform sampler2D window_source : repeat_disable, filter_linear;
uniform float airplane_x = -220.0;
uniform bool windows_only = false;

float oval(vec2 point, vec2 center, vec2 radius) {
	return (length((point - center) / radius) - 1.0) * min(radius.x, radius.y);
}

float aircraft_shadow(vec2 point) {
	vec2 angled = vec2(point.x + point.y * 0.33, point.y - point.x * 0.10);
	float span = abs(angled.y);
	float wing_length = angled.y < 0.0 ? 79.0 : 105.0;
	float taper = clamp(span / wing_length, 0.0, 1.0);
	float leading = mix(38.0, -29.0, taper);
	float trailing = mix(-27.0, -50.0, taper);
	float wing = max(span - wing_length, max(angled.x - leading, trailing - angled.x));
	float tail = max(span - 32.0, max(angled.x - (-66.0 - span * 0.62), -103.0 - angled.x));
	float fuselage = oval(angled, vec2(3.0, 0.0), vec2(106.0, 11.0));
	float engine = oval(angled, vec2(68.0, 0.0), vec2(38.0, 11.5));
	float propeller = oval(angled, vec2(108.0, 0.0), vec2(4.0, 28.0));
	float outline = min(min(wing, tail), min(fuselage, min(engine, propeller)));
	return 1.0 - smoothstep(-2.5, 3.5, outline);
}

vec4 floor_projection(vec2 uv) {
	vec2 floor_point = uv * vec2(2170.0, 206.0);
	float window_x = (floor_point.x - uv.y * 46.0 + 19.0) / 2170.0;
	float glass = texture(window_source, vec2(window_x, 270.5 / 725.0)).r;
	float beam = smoothstep(0.23, 0.59, glass);
	float floor_fade = smoothstep(0.02, 0.31, uv.y) * (1.0 - smoothstep(0.76, 0.99, uv.y));
	float shade = 0.0;
	if (abs(floor_point.x - airplane_x) < 160.0) {
		vec2 plane_point = vec2(floor_point.x - airplane_x, (floor_point.y - 105.0) * 1.65);
		shade = aircraft_shadow(plane_point);
	}
	vec3 tint = mix(vec3(0.87), vec3(0.09), shade);
	return vec4(tint, mix(0.115, 0.31, shade) * beam * floor_fade);
}

vec4 window_blur(vec2 uv) {
	float glass = texture(window_source, vec2(uv.x, (253.0 + uv.y * 56.0) / 725.0)).r;
	float glass_mask = smoothstep(0.25, 0.52, glass);
	float dx = uv.x * 2170.0 - airplane_x;
	float dy = (uv.y - 0.50) * 56.0;
	vec2 smear = vec2((dx + dy * 1.15) / 142.0, dy / 27.0);
	float coverage = 1.0 - smoothstep(0.18, 1.0, dot(smear, smear));
	return vec4(vec3(0.035), coverage * glass_mask * 0.76);
}

void fragment() {
	COLOR = windows_only ? window_blur(UV) : floor_projection(UV);
}
