// Suelo de selva anime (Etapa C, revisión C2). Zonas con borde limpio en lugar de manchas difuminadas:
// - camino de tierra con borde irregular y dos tonos;
// - franja de hojarasca junto al camino y bajo los árboles;
// - musgo y humedad bajo las copas (posición de los árboles en 'arboles');
// - hierba en los claros, en dos tonos con manchas grandes de borde definido;
// - a distancia el suelo se unifica hacia 'c_lejos' para no hacer ruido.
// Iluminación por bandas común (anime_luz.gdshaderinc). Sin texturas.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

uniform vec3 c_hierba : source_color = vec3(0.19, 0.29, 0.11);
uniform vec3 c_hierba_clara : source_color = vec3(0.27, 0.35, 0.14);
uniform vec3 c_hierba_seca : source_color = vec3(0.31, 0.32, 0.16);
uniform vec3 c_musgo : source_color = vec3(0.13, 0.23, 0.1);
uniform vec3 c_humedo : source_color = vec3(0.1, 0.17, 0.11);
uniform vec3 c_hojarasca : source_color = vec3(0.27, 0.21, 0.13);
uniform vec3 c_hojarasca_osc : source_color = vec3(0.19, 0.15, 0.1);
uniform vec3 c_tierra : source_color = vec3(0.36, 0.27, 0.17);
uniform vec3 c_tierra_oscura : source_color = vec3(0.27, 0.2, 0.13);
uniform vec3 c_lejos : source_color = vec3(0.15, 0.22, 0.12);
// camino: x(z) = x0 + A·sin(f·z + fase) + 0.4·A·sin(2.3·f·z + 1.7); w = ancho
uniform vec4 camino = vec4(3.0, 0.07, 0.4, 2.6);
uniform float camino_x0 = 0.0;
uniform float camino_z_fin = -90.0;
uniform vec4 arboles[64];     // xz y radio de la copa
uniform int n_arboles = 0;
uniform float lejos_inicio = 35.0;
uniform float lejos_fin = 120.0;
uniform float mascara_contorno : hint_range(0.0, 1.0) = 0.6;

varying vec3 wpos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

float camino_x(float z) {
	return camino_x0 + camino.x * sin(camino.y * z + camino.z) + 0.4 * camino.x * sin(2.3 * camino.y * z + 1.7);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	// camino con borde irregular (el borde se mueve, pero el corte es limpio)
	float borde_ruido = (vnoise(p * 0.55) - 0.5) * 0.7;
	float dcam = abs(p.x - camino_x(p.y)) + borde_ruido;
	float en_camino = step(camino_z_fin, p.y);
	float m_camino = (1.0 - smoothstep(camino.w * 0.5 - 0.06, camino.w * 0.5 + 0.06, dcam)) * en_camino;
	float m_orilla = (1.0 - smoothstep(camino.w * 0.5 + 0.4, camino.w * 0.5 + 0.55, dcam - (vnoise(p * 0.3 + 9.0) - 0.5) * 1.4)) * en_camino;
	// influencia de las copas cercanas (humedad, musgo, hojarasca)
	float bajo_copa = 0.0;
	for (int i = 0; i < n_arboles; i++) {
		float d = length(p - arboles[i].xy);
		bajo_copa = max(bajo_copa, 1.0 - smoothstep(arboles[i].z * 0.25, arboles[i].z * 1.1, d));
	}
	// borde de las zonas roto a dos escalas: sin discos ni manchas redondas
	float roto = (vnoise(p * 0.32 + 2.0) - 0.5) * 0.55 + (vnoise(p * 1.3 + 7.0) - 0.5) * 0.25;
	// claros: hierba en tres tonos con manchas de borde definido
	float n1 = vnoise(p * 0.06) * 0.55 + vnoise(p * 0.21 + 4.0) * 0.3 + vnoise(p * 0.9 + 1.0) * 0.15;
	vec3 col = mix(c_hierba, c_hierba_clara, smoothstep(0.56, 0.585, n1));
	col = mix(col, c_hierba_seca, smoothstep(0.66, 0.685, vnoise(p * 0.11 + 21.0) * 0.8 + vnoise(p * 0.7) * 0.2) * 0.85);
	col = mix(col, c_hierba * 0.82, smoothstep(0.62, 0.645, vnoise(p * 0.5 + 30.0)) * 0.6);
	// musgo bajo las copas, con charcos de humedad dentro
	float hum = smoothstep(0.42, 0.46, bajo_copa + roto);
	col = mix(col, c_musgo, hum);
	col = mix(col, c_humedo, smoothstep(0.64, 0.67, vnoise(p * 0.16 + 13.0) + roto * 0.3) * hum);
	// hojarasca: orilla del camino y manchas irregulares al pie de los árboles, con hojas sueltas
	float hoj = max(m_orilla, smoothstep(0.66, 0.69, bajo_copa * 0.7 + vnoise(p * 0.5 + 5.0) * 0.32 + roto * 0.5));
	float hojas = smoothstep(0.55, 0.6, vnoise(p * 3.2 + 40.0)) * (1.0 - smoothstep(10.0, 30.0, dist));
	vec3 hojarasca = mix(c_hojarasca, c_hojarasca_osc, max(hojas, smoothstep(0.5, 0.55, vnoise(p * 0.9 + 17.0)) * 0.6));
	col = mix(col, hojarasca, hoj);
	// hojas caídas sueltas sobre el musgo
	col = mix(col, c_hojarasca, hum * (1.0 - hoj) * smoothstep(0.72, 0.75, vnoise(p * 2.6 + 50.0)) * (1.0 - smoothstep(8.0, 22.0, dist)));
	// tierra del camino en dos tonos
	vec3 tierra = mix(c_tierra, c_tierra_oscura, smoothstep(0.55, 0.6, vnoise(p * 0.4 + 3.0)) * 0.7);
	col = mix(col, tierra, m_camino);
	// grano fino solo cerca de la cámara (sin ruido a distancia)
	col *= 1.0 + (vnoise(p * 2.1) - 0.5) * 0.07 * (1.0 - smoothstep(8.0, 25.0, dist));
	col = mix(col, c_lejos, smoothstep(lejos_inicio, lejos_fin, dist) * 0.75);
	ALBEDO = col;
	ROUGHNESS = mascara_contorno;
}
