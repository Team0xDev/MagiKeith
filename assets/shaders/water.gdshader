shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.12, 0.32, 0.48, 0.82);
uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.28, 0.95);
uniform float wave_speed : hint_range(0.1, 3.0) = 0.8;
uniform float wave_strength : hint_range(0.0, 0.5) = 0.08;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.15;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.12;
uniform sampler2D noise_tex : source_color, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;
	float wave = sin(world_pos.x * 0.4 + t) * cos(world_pos.z * 0.35 + t * 0.7);
	VERTEX.y += wave * wave_strength;
	NORMAL = normalize(NORMAL + vec3(wave * 0.15, 0.0, wave * 0.1));
}

void fragment() {
	float t = TIME * 0.25;
	vec2 uv1 = world_pos.xz * 0.08 + vec2(t * 0.03, t * 0.02);
	vec2 uv2 = world_pos.xz * 0.12 - vec2(t * 0.025, -t * 0.035);
	
	float n1 = texture(noise_tex, uv1).r;
	float n2 = texture(noise_tex, uv2).g;
	float foam = smoothstep(0.55, 0.85, n1 * 0.6 + n2 * 0.4);
	
	vec3 col = mix(water_color.rgb, deep_color.rgb, n1 * 0.5);
	col = mix(col, vec3(0.7, 0.85, 0.95), foam * 0.25);
	
	ALBEDO = col;
	ALPHA = mix(water_color.a, deep_color.a, n1 * 0.4);
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value + foam * 0.2;
	SPECULAR = 0.6;
}
