shader_type canvas_item;
render_mode unshaded;

uniform float lift : hint_range(0.0, 0.3) = 0.14;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), lift);
}
