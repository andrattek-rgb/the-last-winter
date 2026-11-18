shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float exposure : hint_range(0.4, 1.0) = 0.83;
uniform float grain : hint_range(0.0, 0.08) = 0.035;
uniform float vignette : hint_range(0.0, 0.4) = 0.18;

float noise_at(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 scene = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float luma = dot(scene, vec3(0.2126, 0.7152, 0.0722));
	float frame = floor(TIME * 12.0);
	float texture_noise = noise_at(floor(FRAGCOORD.xy * 0.5) + vec2(frame * 17.0, frame * 7.0)) - 0.5;
	float flicker = (noise_at(vec2(frame, 3.0)) - 0.5) * 0.024;
	vec2 edge = SCREEN_UV * 2.0 - 1.0;
	float falloff = smoothstep(0.25, 1.45, dot(edge, edge));
	float tone = (luma * exposure + 0.012) * (1.0 - falloff * vignette);
	COLOR = vec4(vec3(clamp(tone + texture_noise * grain + flicker, 0.0, 1.0)), 1.0);
}
