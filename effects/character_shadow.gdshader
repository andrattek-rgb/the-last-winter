shader_type canvas_item;
render_mode unshaded;

uniform float opacity : hint_range(0.0, 0.7) = 0.42;

void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float distance_squared = dot(point, point);
	float falloff = exp(-2.6 * distance_squared) * (1.0 - smoothstep(0.48, 1.0, distance_squared));
	COLOR = vec4(vec3(0.035), opacity * COLOR.a * falloff);
}
