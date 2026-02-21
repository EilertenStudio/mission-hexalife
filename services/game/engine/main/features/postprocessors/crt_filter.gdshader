shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

const float magnify = 1.0;
const float curvature = 10.0;
const float scanlines_height = 180.0;
const float vignette = 0.2;

void fragment() {
	COLOR = texture(screen_texture, SCREEN_UV);
	
	vec2 centered_uv = (SCREEN_UV * 2.0 - 1.0) / magnify;
	COLOR = vec4(centered_uv, 0.0, 1.0);
	
	vec2 uv_offset = centered_uv.yx / curvature;
	COLOR = vec4(uv_offset, 0.0, 1.0);
	
	vec2 warped_uv = centered_uv + ((centered_uv * uv_offset) * uv_offset);
	COLOR = vec4(warped_uv, 0.0, 1.0);
	
	vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, 0.2).rgb;
	COLOR = vec4(screen_color, 1.0);
	
	vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y),  1.0));
	screen_color *= cutoff;
	COLOR = vec4(screen_color, 1.0);
	
	vec3 scanlines = vec3(sin(2.0 * warped_uv.y * scanlines_height) * 0.1 + 0.9);
	screen_color *= scanlines;
	COLOR = vec4(screen_color, 1.0);
	
	vec3 vignette_mask = vec3(length(pow(abs(centered_uv), vec2(4.0)) / 2.0));
	screen_color -= vignette_mask * vignette;
	COLOR = vec4(screen_color, 1.0);
	
	//COLOR = vec4(1.0);
}
