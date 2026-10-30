// Material anime de entorno sólido (madera, corteza, mimbre, piedra, roca, tela).
// Misma interfaz básica que mundo_pbr.gdshader (textura por UV o triplanar, tinte, musgo arriba,
// oclusión del color de vértice G y balanceo por el color R) pero con aspecto pintado:
// - la textura se toma de un mip alto ('pintado') y se mezcla con su color plano ('detalle'),
//   así se conservan las vetas grandes y desaparece el ruido fotográfico;
// - el musgo es una masa de color con borde limpio, no otra foto;
// - iluminación por bandas (anime_luz.gdshaderinc), sin mapas normales.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform bool usar_uv = false;
uniform float escala = 0.4;
uniform vec3 color_plano : source_color = vec3(0.55, 0.42, 0.3); // color medio del material
uniform vec3 tinte = vec3(1.0);
uniform float detalle : hint_range(0.0, 1.0) = 0.45;   // 0 = color plano, 1 = textura completa
uniform float pintado : hint_range(0.0, 6.0) = 2.5;    // nivel de mip (más alto = más plano)
uniform float contraste_detalle : hint_range(0.0, 3.0) = 1.4;
uniform float variacion : hint_range(0.0, 0.5) = 0.1;  // manchas grandes de tono
uniform float saturacion : hint_range(0.0, 2.0) = 1.05;
uniform float musgo : hint_range(0.0, 1.0) = 0.0;
uniform float musgo_vcolor : hint_range(0.0, 1.0) = 0.0;
uniform vec3 musgo_color : source_color = vec3(0.3, 0.46, 0.2);
uniform float oclusion_vertice : hint_range(0.0, 1.0) = 0.6;
uniform int balanceo_modo = 0;        // 0 nada, 1 viento, 2 puente colgante
uniform float balanceo = 0.0;
uniform bool doble_cara = false;
uniform float mascara_contorno : hint_range(0.0, 1.0) = 0.8;

varying vec3 wpos;
varying vec3 wnrm;
varying float vao;
varying float vmoss;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s = COLOR.r * balanceo;
	if (balanceo_modo == 1 && s > 0.0) {
		float t = TIME * 1.1 + dot(w, vec3(0.13, 0.0, 0.09));
		VERTEX += (inverse(MODEL_MATRIX) * vec4(sin(t) * 0.6 + sin(t * 2.3) * 0.25, 0.0, cos(t * 0.8) * 0.5, 0.0)).xyz * s;
	} else if (balanceo_modo == 2 && s > 0.0) {
		float t = TIME;
		VERTEX += (inverse(MODEL_MATRIX) * vec4(sin(t * 1.25) * 0.05, sin(t * 1.9 + 0.7) * 0.035, cos(t * 1.05) * 0.04, 0.0)).xyz * s;
	}
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vao = mix(1.0, COLOR.g, oclusion_vertice);
	vmoss = COLOR.b;
}

vec3 muestra(vec3 n, vec2 uv) {
	if (usar_uv) {
		return textureLod(albedo_tex, uv * escala, pintado).rgb;
	}
	vec3 w = pow(abs(n), vec3(6.0));
	w /= (w.x + w.y + w.z);
	vec3 p = wpos * escala;
	return textureLod(albedo_tex, p.zy, pintado).rgb * w.x + textureLod(albedo_tex, p.xz, pintado).rgb * w.y + textureLod(albedo_tex, p.xy, pintado).rgb * w.z;
}

void fragment() {
	vec3 n = normalize(wnrm);
	if (doble_cara && !FRONT_FACING) {
		n = -n;
	}
	vec3 t = muestra(n, UV);
	// detalle relativo: la textura solo aporta la variación de luminancia alrededor del color plano
	float lt = dot(t, vec3(0.299, 0.587, 0.114));
	vec3 col = color_plano * (1.0 + (lt - 0.45) * contraste_detalle * detalle);
	col = mix(col, t * (color_plano / max(vec3(0.05), vec3(0.45))), detalle * 0.35);
	float big = vnoise3(wpos * 0.13) - 0.5;
	col *= tinte * (1.0 + big * variacion * 2.0);
	if (musgo > 0.0 || musgo_vcolor > 0.0) {
		float nz = vnoise3(wpos * 1.1) * 0.65 + vnoise3(wpos * 3.3) * 0.35;
		float up = n.y + (nz - 0.5) * 0.8 + vmoss * musgo_vcolor;
		float m = smoothstep(1.0 - musgo, 1.0 - musgo + 0.06, up) * step(0.001, musgo + musgo_vcolor * vmoss);
		col = mix(col, musgo_color * (0.9 + nz * 0.2), m);
	}
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturacion), vec3(0.0));
	ALBEDO = col * vao;
	ROUGHNESS = mascara_contorno;
}
