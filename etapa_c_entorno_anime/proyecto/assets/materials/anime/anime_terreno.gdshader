// Suelo anime de la selva (Etapa C): color por vértice (parches de musgo, hierba, hojarasca y tierra)
// con una variación de tono a dos escalas para que no sea una superficie verde uniforme.
// Iluminación por bandas común (anime_luz.gdshaderinc). Sin texturas fotográficas.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

uniform float saturacion : hint_range(0.0, 2.0) = 1.12;
uniform float detalle : hint_range(0.0, 1.0) = 0.32;     // variación de tono dentro de cada parche
uniform float escala_ruido = 0.42;
uniform float mascara_contorno : hint_range(0.0, 1.0) = 0.6;

varying vec3 vcolor;
varying vec3 wpos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vcolor = COLOR.rgb;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = vnoise2(wpos.xz * escala_ruido) * 0.6 + vnoise2(wpos.xz * escala_ruido * 3.1 + 7.3) * 0.4;
	vec3 col = vcolor * (1.0 + (n - 0.5) * detalle * 2.0);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturacion), vec3(0.0));
	ALBEDO = col;
	ROUGHNESS = mascara_contorno;
}
