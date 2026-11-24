shader_type canvas_item;
render_mode unshaded;

uniform vec2 spot_center;
uniform vec2 spot_radius = vec2(266.0, 205.0);
uniform vec2 shadow_origin;
uniform float safe_x;
uniform float intensity;
uniform vec4 cover_rects[4];

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

bool blocks_ray(vec4 bounds, vec2 target) {
	vec2 direction = target - shadow_origin;
	vec2 nonzero = mix(vec2(0.0001), direction, step(vec2(0.0001), abs(direction)));
	vec2 a = (bounds.xy - shadow_origin) / nonzero;
	vec2 b = (bounds.zw - shadow_origin) / nonzero;
	vec2 near = min(a, b);
	vec2 far = max(a, b);
	return max(max(near.x, near.y), 0.0) < min(min(far.x, far.y), 1.0);
}

void fragment() {
	float radius = length((world_position - spot_center) / spot_radius);
	float edge = 1.0 - smoothstep(0.76, 1.0, radius);
	float cutoff = smoothstep(safe_x, safe_x + 18.0, world_position.x);
	bool shaded = false;
	for (int i = 0; i < 4; i++) {
		shaded = shaded || blocks_ray(cover_rects[i], world_position);
	}
	vec3 tone = shaded ? vec3(0.055) : vec3(0.97);
	float power = shaded ? 0.24 : mix(0.55, 0.38, radius);
	COLOR = vec4(tone, edge * cutoff * intensity * power);
}
