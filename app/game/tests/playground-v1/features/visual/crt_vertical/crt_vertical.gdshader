shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 0.5, 0.01) = 0.2;
uniform float period_px : hint_range(2.0, 8.0, 1.0) = 2.0;
uniform float stripe_width_px : hint_range(1.0, 4.0, 1.0) = 1.0;

void fragment() {
	vec4 frame_color = texture(screen_texture, SCREEN_UV);
	float screen_x = floor(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x);
	float stripe_phase = mod(screen_x, period_px);
	float stripe_mask = 1.0 - step(stripe_width_px, stripe_phase);
	float brightness = 1.0 - strength * stripe_mask;

	COLOR = vec4(frame_color.rgb * brightness, frame_color.a);
}
