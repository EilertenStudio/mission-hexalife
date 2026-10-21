shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	vec3 scene_color = texture(screen_texture, SCREEN_UV).rgb;
	float upper_shade = (1.0 - smoothstep(0.0, 0.72, UV.y)) * 0.52;
	float right_shade = smoothstep(0.36, 1.0, UV.x) * 0.55;
	float shade = clamp(upper_shade + right_shade, 0.0, 0.68);
	vec3 shadow_tint = vec3(0.16, 0.22, 0.31);
	vec3 color_grade = mix(vec3(0.94, 0.97, 1.0), shadow_tint, shade);
	COLOR = vec4(scene_color * color_grade, 1.0);
}
