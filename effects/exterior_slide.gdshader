shader_type canvas_item;
render_mode unshaded;

uniform sampler2D outgoing : filter_linear, repeat_disable;
uniform sampler2D incoming : hint_screen_texture, filter_linear, repeat_disable;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float edge = 1.0 - progress;
	float blur_strength = pow(max(0.0, sin(progress * PI)), 0.65);
	float radius = 0.058 * blur_strength;
	vec2 old_uv = SCREEN_UV + vec2(progress, 0.0);
	vec2 new_uv = SCREEN_UV - vec2(edge, 0.0);
	float seam = max(SCREEN_PIXEL_SIZE.x, 0.024 * blur_strength);
	float incoming_weight = smoothstep(edge - seam, edge + seam, SCREEN_UV.x);
	vec3 before = vec3(0.0);
	vec3 after = vec3(0.0);
	for (int tap = -8; tap <= 8; tap++) {
		float weight = (9.0 - abs(float(tap))) / 81.0;
		vec2 offset = vec2(float(tap) * radius / 8.0,
			sin(float(tap) * 2.4) * 3.0 * SCREEN_PIXEL_SIZE.y * blur_strength);
		before += texture(outgoing, old_uv + offset).rgb * weight;
		after += texture(incoming, new_uv + offset).rgb * weight;
	}
	COLOR = vec4(mix(before, after, incoming_weight), 1.0);
}
