// Iluminación anime común (cel shading) para todos los materiales del estilo anime.
// - Bandas: sombra / tono medio / luz, con umbrales y suavizado del borde configurables.
// - La sombra no es negra: el lado oscuro recibe la luz teñida con 'sombra_color'.
// - Sombras proyectadas del sol endurecidas para que encajen con las bandas.
// - Brillo especular en forma de mancha (umbral sobre Blinn-Phong) y luz de borde a contraluz.
// Incluir después de declarar 'render_mode'. El shader que lo incluye decide ALBEDO y la máscara
// de contorno (ROUGHNESS, ver anime_contorno_post.gdshader).

uniform vec3 sombra_color : source_color = vec3(0.56, 0.5, 0.72);   // tono del lado en sombra
uniform float sombra_fuerza : hint_range(0.0, 1.0) = 0.6;           // cuánta luz (teñida) llega al lado en sombra
uniform int bandas : hint_range(2, 3) = 3;
uniform float umbral_sombra : hint_range(-1.0, 1.0) = 0.02;         // dónde cae la línea luz/sombra (N·L)
uniform float umbral_luz : hint_range(-1.0, 1.0) = 0.55;            // tercera banda (luz plena)
uniform float tono_medio : hint_range(0.0, 1.0) = 0.82;             // brillo de la banda intermedia
uniform float suavizado : hint_range(0.001, 0.3) = 0.025;           // anchura del borde entre bandas
uniform float intensidad_luz : hint_range(0.0, 3.0) = 1.0;
uniform float dureza_sombra : hint_range(0.0, 1.0) = 0.85;          // 1 = sombras proyectadas de borde duro
uniform vec3 especular_color : source_color = vec3(1.0, 0.97, 0.9);
uniform float especular_fuerza : hint_range(0.0, 2.0) = 0.0;
uniform float especular_tamano : hint_range(0.0, 1.0) = 0.25;       // tamaño de la mancha de brillo
uniform vec3 borde_color : source_color = vec3(1.0, 0.95, 0.85);
uniform float borde_fuerza : hint_range(0.0, 2.0) = 0.0;
uniform float borde_ancho : hint_range(0.0, 1.0) = 0.3;
uniform float translucidez : hint_range(0.0, 1.0) = 0.0;             // hojas: luz que atraviesa a contraluz

float anime_banda(float x, float u, float s) {
	return smoothstep(u - s, u + s, x);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float att = ATTENUATION;
	float sombra = 1.0;
	if (LIGHT_IS_DIRECTIONAL) {
		// la sombra proyectada se endurece; en el lado ya oscuro por N·L no aporta nada (evita acné)
		sombra = mix(att, smoothstep(0.35, 0.65, att), dureza_sombra);
		att = 1.0;
	}
	float luz = anime_banda(ndl, umbral_sombra, suavizado) * sombra;
	float tono = luz * tono_medio;
	if (bandas >= 3) {
		tono = mix(tono, 1.0, anime_banda(ndl, umbral_luz, suavizado) * sombra);
	} else {
		tono = luz;
	}
	vec3 lado_oscuro = sombra_color * sombra_fuerza;
	vec3 k = mix(lado_oscuro, vec3(1.0), tono);
	vec3 lc = LIGHT_COLOR * att * intensidad_luz / PI;
	DIFFUSE_LIGHT += lc * k;
	if (translucidez > 0.0) {
		DIFFUSE_LIGHT += lc * translucidez * anime_banda(-ndl, 0.2, 0.15) * sombra * 0.6;
	}
	if (especular_fuerza > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float nh = max(dot(NORMAL, h), 0.0);
		float brillo = pow(nh, mix(8.0, 160.0, 1.0 - especular_tamano));
		SPECULAR_LIGHT += lc * especular_color * especular_fuerza * anime_banda(brillo, 0.5, suavizado * 2.0) * luz;
	}
	if (borde_fuerza > 0.0) {
		float fr = 1.0 - max(dot(NORMAL, VIEW), 0.0);
		float borde = anime_banda(fr, 1.0 - borde_ancho, suavizado * 1.5) * anime_banda(ndl, -0.3, 0.2);
		SPECULAR_LIGHT += lc * borde_color * borde_fuerza * borde * sombra;
	}
}
