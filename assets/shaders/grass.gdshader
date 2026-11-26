shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 grass_color : source_color = vec4(0.2, 0.4, 0.14, 1.0);
uniform vec4 grass_tip_color : source_color = vec4(0.38, 0.58, 0.22, 1.0);
uniform vec3 player_position = vec3(0.0);
uniform float interact_radius : hint_range(0.5, 6.0) = 2.4;
uniform float bend_strength : hint_range(0.0, 2.5) = 1.3;
uniform float wind_strength : hint_range(0.0, 1.5) = 0.35;
uniform float wind_speed : hint_range(0.1, 4.0) = 1.5;

varying float height_factor;

void vertex() {
	// UV.y = 1 base, 0 punta
	height_factor = 1.0 - UV.y;

	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Viento
	float wind = sin(TIME * wind_speed + world_pos.x * 0.9 + world_pos.z * 0.7)
			   * cos(TIME * wind_speed * 0.65 + world_pos.z * 0.55);
	VERTEX.x += wind * wind_strength * height_factor * 0.4;
	VERTEX.z += wind * wind_strength * 0.55 * height_factor * 0.3;

	// Reacción al jugador
	vec3 to_player = world_pos - player_position;
	to_player.y = 0.0;
	float dist = length(to_player);
	float influence = 1.0 - smoothstep(0.0, interact_radius, dist);
	influence = pow(influence, 1.4);

	if (influence > 0.01) {
		vec3 push_dir = normalize(to_player + vec3(0.001, 0.0, 0.001));
		VERTEX.xz += push_dir.xz * influence * bend_strength * height_factor * 1.0;
		VERTEX.y -= influence * height_factor * 0.3;
	}
}

void fragment() {
	vec3 col = mix(grass_color.rgb, grass_tip_color.rgb, height_factor * height_factor);
	ALBEDO = col;
	ROUGHNESS = 0.88;
	SPECULAR = 0.12;
}
