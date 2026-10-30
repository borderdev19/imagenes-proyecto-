// Copa anime (Etapa C, revisión C2): racimos de hojas dibujadas (atlas en escala de grises) sobre
// tarjetas cuyas normales ya vienen hacia fuera de cada racimo. Cada racimo se ilumina como un volumen
// propio y la copa entera como un grupo de volúmenes, con el borde dentado de las hojas.
// - El color sale del valor del atlas: oscuro = color_hoja, claro = color_luz (sin foto).
// - Las dos caras de la tarjeta comparten la normal del racimo (no se invierte en la cara trasera).
// - Viento por el color R del vértice; variación de tono por racimo en el color G.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec3 color_hoja : source_color = vec3(0.12, 0.3, 0.12);
uniform vec3 color_luz : source_color = vec3(0.36, 0.56, 0.2);
uniform float variacion : hint_range(0.0, 0.5) = 0.14;
uniform float corte_alfa : hint_range(0.0, 1.0) = 0.5;
uniform float viento = 0.08;
uniform float viento_vel = 0.9;
uniform float mascara_contorno : hint_range(0.0, 1.0) = 0.9;

varying float vvar;

void vertex() {
	vvar = COLOR.g;
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * viento_vel + dot(w, vec3(0.17, 0.11, 0.13));
	vec3 off = vec3(sin(t) + 0.35 * sin(t * 2.3), 0.2 * sin(t * 1.6), cos(t * 0.8)) * COLOR.r * viento;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(off, 0.0)).xyz;
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = corte_alfa;
	float v = c.r;
	vec3 col = mix(color_hoja, color_luz, smoothstep(0.42, 0.95, v));
	col *= 1.0 + (vvar - 0.5) * variacion * 2.0;
	ALBEDO = max(col, vec3(0.0));
	ROUGHNESS = mascara_contorno;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
