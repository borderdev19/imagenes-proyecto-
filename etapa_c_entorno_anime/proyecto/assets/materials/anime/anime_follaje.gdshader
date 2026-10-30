// Follaje anime (copas, hojas tropicales, helechos, arbustos, hierba). Conserva el viento, la
// translucidez y el doblado al paso del jugador (uniforme global jugador_pos) de hojas_mundo y
// planta, y añade:
// - normales esféricas: las hojas de una copa se iluminan como una sola masa (sombreado en bloques
//   típico del anime) en lugar de cientos de tarjetas sueltas;
// - color plano por tono con dos bandas y sombra teñida (anime_luz.gdshaderinc);
// - máscara de contorno alta: el contorno de pantalla no dibuja líneas en cada hoja.
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

global uniform vec3 jugador_pos;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec3 color_hoja : source_color = vec3(0.36, 0.62, 0.24);
uniform vec3 color_punta : source_color = vec3(0.62, 0.8, 0.3);   // puntas e iluminadas
uniform float detalle : hint_range(0.0, 1.0) = 0.35;            // cuánto de la textura sobrevive
uniform float variacion : hint_range(0.0, 0.5) = 0.12;
uniform float corte_alfa : hint_range(0.0, 1.0) = 0.42;
uniform int viento_modo = 0;                // 0 = según color R (copas), 1 = según altura (sotobosque)
uniform float viento = 0.15;
uniform float viento_vel = 1.1;
uniform float doblar = 0.35;
uniform float doblar_radio = 1.4;
uniform float normales_esfericas : hint_range(0.0, 1.0) = 0.75;
uniform vec3 centro_copa = vec3(0.0, 1.0, 0.0);   // espacio local de la malla
uniform float mascara_contorno : hint_range(0.0, 1.0) = 1.0;

varying float vvar;
varying float vtip;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vvar = hash3(floor(origin * 0.7));
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s;
	if (viento_modo == 0) {
		s = COLOR.r;
	} else {
		s = clamp((w.y - origin.y) * 0.8, 0.0, 1.2);
	}
	vtip = clamp(s, 0.0, 1.0);
	float t = TIME * viento_vel + dot(w, vec3(0.21, 0.13, 0.17)) + vvar * 6.0;
	vec3 off = vec3(sin(t) + 0.4 * sin(t * 2.7), sin(t * 1.7) * 0.3, cos(t * 0.9) + 0.3 * sin(t * 3.1)) * s * viento;
	vec2 d = w.xz - jugador_pos.xz;
	float r = length(d);
	float cerca = (1.0 - smoothstep(0.3, doblar_radio, r)) * (1.0 - smoothstep(0.5, 2.0, abs(w.y - jugador_pos.y - 0.6)));
	vec2 push = (r > 0.001 ? d / r : vec2(0.0)) * cerca * doblar * max(s, 0.3);
	off += vec3(push.x, -length(push) * 0.3, push.y);
	VERTEX += (inverse(MODEL_MATRIX) * vec4(off, 0.0)).xyz;
	vec3 ns = VERTEX - centro_copa;
	ns = length(ns) > 1e-4 ? normalize(ns) : NORMAL;
	NORMAL = normalize(mix(NORMAL, ns, normales_esfericas));
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	if (c.a < corte_alfa) {
		discard;
	}
	float lt = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 base = mix(color_hoja, color_punta, smoothstep(0.35, 0.9, vtip) * 0.6);
	// la textura solo aporta nervios y manchas alrededor del tono base (no aclara el conjunto)
	vec3 col = base * (1.0 + (lt - 0.45) * 1.1 * detalle);
	col *= 1.0 + (vvar - 0.5) * variacion * 2.0;
	ALBEDO = max(col, vec3(0.0));
	ROUGHNESS = mascara_contorno;
	// Godot invierte la normal en las caras traseras; con normales esféricas ambas caras deben
	// compartir la normal de la masa, así que se deshace ese giro
	if (!FRONT_FACING && normales_esfericas >= 0.5) {
		NORMAL = -NORMAL;
	}
}
