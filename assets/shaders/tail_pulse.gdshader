shader_type spatial;
// Pulso de la punta de la cola. Reproduce los efectos del material de Blender:
//   factor = clamp(mascara + L(sin(frame * 0.18)), 0, 1);   color = mix(color_ruido, oscuro, factor)      (24 fps)
// L(s) = curva del driver (ajuste cúbico, error < 0.001). Período del pulso: 1.454 s.
// El color del ruido es HDR (llega a ~5.5): la textura se guardó dividida por 6 y se multiplica de nuevo acá.
//
// Texturas:  Cat_Tail_PulseColor.png -> color (el hint source_color la lee como sRGB)
//            Cat_Tail_PulseMask.png  -> datos lineales (sin source_color); en Import dejala en Compress Mode = Lossless
// Para ver los colores como en Blender (la escena usa Filmic), poné Tonemap = Filmic en el WorldEnvironment.

uniform sampler2D pulse_color : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pulse_mask : filter_linear_mipmap, repeat_enable;
uniform float color_scale = 6.0;
uniform float speed = 4.3200;                  // 0.18 rad/cuadro * 24 cuadros/s
uniform vec4 curve = vec4(0.52318, 0.41271, 0.02886, -0.03937);   // L(s) = c0 + c1*s + c2*s^2 + c3*s^3
uniform float dark_level = 0.0121;             // color oscuro del Mix original
uniform float glow_energy : hint_range(0.0, 8.0) = 0.0;   // 0 = igual que en Blender; subilo para que brille de verdad

void fragment() {
	float s = sin(TIME * speed);
	float L = curve.x + s * (curve.y + s * (curve.z + s * curve.w));
	float f = clamp(texture(pulse_mask, UV).r + L, 0.0, 1.0);
	vec3 col = mix(texture(pulse_color, UV).rgb * color_scale, vec3(dark_level), f);
	ALBEDO = col;          // si ves valores raros por encima de 1, probá: ALBEDO = min(col, vec3(1.0)); y subí glow_energy
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = col * glow_energy;
}
