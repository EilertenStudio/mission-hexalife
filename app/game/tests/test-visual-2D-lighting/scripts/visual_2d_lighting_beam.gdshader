shader_type canvas_item;
render_mode unshaded;

uniform vec2 viewport_pixels = vec2(384.0, 288.0);
uniform vec2 source_pixel = vec2(176.0, 144.0);
uniform vec2 target_pixel = vec2(352.0, 144.0);
uniform vec4 beam_color : source_color = vec4(0.7765, 0.9373, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.9608, 0.9882, 1.0, 1.0);
uniform float beam_enabled = 1.0;
uniform float impact_enabled = 1.0;
uniform float impact_radius = 15.0;

void fragment() {
	vec2 pixel = UV * viewport_pixels;
	vec3 result_rgb = vec3(0.0);
	float result_alpha = 0.0;

	if (beam_enabled > 0.5) {
		vec2 delta = target_pixel - source_pixel;
		float beam_length = max(length(delta), 0.001);
		vec2 axis = delta / beam_length;
		vec2 relative = pixel - source_pixel;
		float along = dot(relative, axis);
		float progress = along / beam_length;
		float distance_from_axis = abs(axis.x * relative.y - axis.y * relative.x);
		float cone_width = mix(1.5, 29.0, clamp(progress, 0.0, 1.0));
		float edge = 1.0 - smoothstep(cone_width - 5.0, cone_width + 2.0, distance_from_axis);
		float core = 1.0 - smoothstep(1.0, 3.5, distance_from_axis);
		float start_fade = smoothstep(0.0, 5.0, along);
		float end_fade = 1.0 - smoothstep(beam_length - 6.0, beam_length + 1.0, along);
		float axial_fade = start_fade * end_fade;
		float glow = exp(-distance_from_axis / max(cone_width, 1.0)) * 0.22;
		result_rgb = mix(beam_color.rgb, core_color.rgb, core);
		result_alpha = max(edge * 0.44, glow) * axial_fade;
		result_alpha = max(result_alpha, core * 0.84 * axial_fade);
	}

	if (impact_enabled > 0.5) {
		float impact_distance = length(pixel - target_pixel);
		float halo = 1.0 - smoothstep(impact_radius * 0.20, impact_radius, impact_distance);
		float impact_core = 1.0 - smoothstep(2.0, 6.0, impact_distance);
		float impact_alpha = max(halo * 0.72, impact_core * 0.96);
		result_rgb = mix(result_rgb, core_color.rgb, impact_core * 0.9);
		result_alpha = max(result_alpha, impact_alpha);
	}

	COLOR = vec4(result_rgb, result_alpha);
}
