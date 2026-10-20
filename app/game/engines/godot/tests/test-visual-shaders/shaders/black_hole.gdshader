shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, fog_disabled;

uniform float lensing_strength : hint_range(0.0, 1.5, 0.01) = 0.78;
uniform float orbit_speed : hint_range(0.0, 2.0, 0.01) = 0.55;
uniform int ray_steps : hint_range(48, 128, 8) = 128;
uniform float disk_tilt_degrees : hint_range(35.0, 82.0, 1.0) = 64.0;

const float SCHWARZSCHILD_RADIUS = 1.0;
const float PHOTON_SPHERE_RADIUS = 1.5;
const float TWO_PI = 6.28318530718;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(cell + vec3(1.0, 1.0, 1.0));
	float low = mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y);
	float high = mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y);
	return mix(low, high, f.z);
}

float star_field(vec2 uv) {
	vec2 grid = uv * vec2(104.0, 58.0);
	vec2 cell = floor(grid);
	float brightness = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 id = cell + vec2(float(x), float(y));
			float seed = hash21(id);
			vec2 point = vec2(hash21(id + 13.7), hash21(id + 71.3));
			vec2 delta = grid - id - point;
			float size = mix(0.018, 0.092, pow(seed, 8.0));
			float sparkle = mix(0.1, 1.0, pow(seed, 5.0));
			brightness += exp(-dot(delta, delta) / max(size * size, 0.0001)) * sparkle;
		}
	}
	return min(brightness, 1.0);
}

vec3 sample_sky(vec3 direction) {
	direction = normalize(direction);
	vec2 spherical_uv = vec2(
		atan(direction.x, direction.z) / TWO_PI + 0.5,
		asin(clamp(direction.y, -1.0, 1.0)) / (0.5 * TWO_PI) + 0.5
	);
	float stars = star_field(spherical_uv);
	float cloud_a = noise3(direction * 5.4 + vec3(1.7, 2.2, 0.0));
	float cloud_b = noise3(direction * 11.0 + vec3(0.0, 0.0, 1.3));
	float nebula = smoothstep(0.46, 0.83, cloud_a * 0.72 + cloud_b * 0.28);
	float latitude_glow = 0.35 + 0.65 * (1.0 - abs(direction.y));
	vec3 sky = mix(vec3(0.003, 0.005, 0.017), vec3(0.014, 0.016, 0.045), latitude_glow);
	sky += vec3(0.075, 0.035, 0.22) * nebula * latitude_glow;
	sky += vec3(0.018, 0.075, 0.19) * smoothstep(0.61, 0.91, cloud_b) * latitude_glow;
	sky += stars * vec3(0.62, 0.76, 1.0) * 1.45;
	return sky;
}

vec3 disk_emission(vec3 position, vec3 camera_origin, vec3 disk_normal, vec3 disk_u, vec3 disk_v, float radius) {
	float inner_radius = 1.34;
	float outer_radius = 4.65;
	float thickness = 0.105 + radius * 0.026;
	float plane_distance = dot(position, disk_normal);
	float vertical_density = exp(-pow(plane_distance / thickness, 2.0) * 1.4);
	float inner_edge = smoothstep(inner_radius, inner_radius + 0.21, radius);
	float outer_edge = 1.0 - smoothstep(outer_radius - 0.52, outer_radius, radius);
	float annulus = inner_edge * outer_edge * vertical_density;
	if (annulus < 0.002) {
		return vec3(0.0);
	}

	vec3 planar = position - disk_normal * plane_distance;
	float angle = atan(dot(planar, disk_v), dot(planar, disk_u));
	float spiral = angle - log(max(radius, 0.001)) * 3.2 + TIME * orbit_speed * 1.8;
	float turbulence = 0.58
		+ 0.21 * sin(spiral * 5.0 + sin(angle * 3.0 + TIME * 0.31) * 1.2)
		+ 0.13 * sin(spiral * 11.0 - TIME * 0.73 + radius * 2.0);
	float eddies = noise3(planar * 2.3 + vec3(0.0, TIME * orbit_speed * 0.22, 0.0));
	turbulence *= mix(0.62, 1.25, eddies);

	vec3 to_camera = normalize(camera_origin - position);
	vec3 orbital_tangent = normalize(cross(disk_normal, normalize(planar)));
	float orbital_speed = sqrt(SCHWARZSCHILD_RADIUS / max(2.0 * radius, 0.001));
	float beta = clamp(orbital_speed * dot(orbital_tangent, to_camera), -0.82, 0.82);
	float doppler = sqrt((1.0 + beta) / (1.0 - beta));
	float gravitational_shift = sqrt(max(0.18, 1.0 - SCHWARZSCHILD_RADIUS / max(radius, 1.001)));
	float relativistic_shift = clamp(doppler * gravitational_shift, 0.45, 1.65);

	float radial_heat = pow(inner_radius / max(radius, inner_radius), 1.32);
	float temperature = clamp(radial_heat * relativistic_shift, 0.0, 1.35);
	vec3 outer_color = mix(vec3(0.11, 0.07, 0.42), vec3(0.10, 0.34, 0.95), smoothstep(0.2, 0.9, eddies));
	vec3 inner_color = mix(vec3(0.39, 0.25, 1.0), vec3(0.74, 0.91, 1.0), smoothstep(0.18, 0.94, temperature));
	vec3 color = mix(outer_color, inner_color, smoothstep(0.0, 0.94, temperature));
	color = mix(color, vec3(0.91, 0.97, 1.0), smoothstep(1.0, 1.48, relativistic_shift) * 0.48);
	float emissivity = (0.26 + 1.65 * pow(radial_heat, 1.15)) * turbulence;
	return color * annulus * emissivity * (0.55 + 0.65 * doppler);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.0, 1.0);
}

void fragment() {
	vec2 ndc = SCREEN_UV * 2.0 - 1.0;
	ndc.y = -ndc.y;
	vec4 view_position = INV_PROJECTION_MATRIX * vec4(ndc, 1.0, 1.0);
	vec3 view_direction = normalize(view_position.xyz / view_position.w);
	vec3 camera_origin = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 ray_direction = normalize((INV_VIEW_MATRIX * vec4(view_direction, 0.0)).xyz);

	float tilt = radians(disk_tilt_degrees);
	vec3 disk_normal = normalize(vec3(0.0, sin(tilt), cos(tilt)));
	vec3 disk_u = vec3(1.0, 0.0, 0.0);
	vec3 disk_v = normalize(cross(disk_normal, disk_u));
	float impact = length(cross(camera_origin, ray_direction));
	float approach = dot(camera_origin, ray_direction);
	vec3 ray_position = camera_origin;
	vec3 color = vec3(0.0);
	float disk_energy = 0.0;
	bool swallowed = false;
	bool interacts = approach < 0.0 && impact < 7.0;
	float gravitational_mass = lensing_strength;

	if (interacts) {
		for (int i = 0; i < 128; i++) {
			if (i >= ray_steps) {
				break;
			}
			float radius = length(ray_position);
			if (radius <= SCHWARZSCHILD_RADIUS) {
				swallowed = true;
				break;
			}
			if (radius > 28.0 && dot(ray_position, ray_direction) > 0.0) {
				break;
			}

			float step_length = clamp(radius * 0.036, 0.026, 0.34);
			float disk_radius = length(ray_position - disk_normal * dot(ray_position, disk_normal));
			vec3 emission = disk_emission(ray_position, camera_origin, disk_normal, disk_u, disk_v, disk_radius);
			disk_energy += length(emission) * step_length;
			color += emission * step_length * 1.42;

			vec3 radial = ray_position / radius;
			vec3 transverse = radial - ray_direction * dot(radial, ray_direction);
			vec3 acceleration = -1.5 * SCHWARZSCHILD_RADIUS * gravitational_mass * transverse / (radius * radius);
			ray_direction = normalize(ray_direction + acceleration * step_length);
			ray_position += ray_direction * step_length;
		}
	}

	vec3 sky = sample_sky(ray_direction);
	float photon_impact = PHOTON_SPHERE_RADIUS * 1.7320508;
	float photon_ring = exp(-pow((impact - photon_impact) / 0.115, 2.0));
	float photon_halo = exp(-pow((impact - photon_impact) / 0.48, 2.0));
	vec3 ring_color = mix(vec3(0.18, 0.48, 1.0), vec3(0.72, 0.80, 1.0), smoothstep(0.12, 0.9, disk_energy));
	color += ring_color * (photon_ring * 1.9 + photon_halo * 0.34) * (0.35 + lensing_strength * 0.75);
	color += sky * exp(-disk_energy * 0.42);
	color += vec3(0.16, 0.27, 0.83) * exp(-abs(impact - photon_impact) * 0.8) * 0.13 * lensing_strength;

	if (swallowed) {
		color = vec3(0.0003, 0.0002, 0.0012);
	}

	ALBEDO = color;
	EMISSION = color * 0.2;
	ALPHA = 1.0;
}
