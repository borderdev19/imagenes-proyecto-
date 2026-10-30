// Contorno de escenario en pantalla (solo Forward+): líneas donde cambia mucho la profundidad o la
// normal. Se dibuja en un QuadMesh de 2×2 pegado a la cámara (ver EstiloAnime.crear_contorno_post).
// La clase de cada píxel viene en la rugosidad que escriben los materiales anime:
//   < 0.85  sólidos (madera, piedra, nidos): profundidad + normales;
//   < 0.95  follaje: solo la silueta de las masas contra lo que hay muy detrás;
//   >= 0.95 personajes: sin línea de pantalla (llevan su propio contorno de casco invertido).
// La línea es el color de la escena oscurecido, se adelgaza y desaparece con la distancia.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

uniform float grosor_px : hint_range(0.5, 4.0) = 1.4;           // a 1080 p de alto
uniform float umbral_profundidad : hint_range(0.0, 1.0) = 0.06;  // salto relativo de profundidad
uniform float umbral_profundidad_follaje : hint_range(0.0, 2.0) = 0.6;
uniform float umbral_normal : hint_range(0.0, 1.0) = 0.45;       // 1 - cos(ángulo)
uniform float oscurecer : hint_range(0.0, 1.0) = 0.42;
uniform vec3 tinte_linea : source_color = vec3(0.32, 0.22, 0.3);
uniform float opacidad : hint_range(0.0, 1.0) = 0.85;
uniform float distancia_ini = 18.0;
uniform float distancia_fin = 60.0;
uniform bool activo = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec4 nr(vec2 uv) {
	vec4 p = texture(normal_tex, uv);
	float r = p.w;
	if (r > 0.5) {
		r = 1.0 - r;
	}
	r /= (127.0 / 255.0);
	return vec4(normalize(p.xyz * 2.0 - 1.0), r);
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 escena = texture(screen_tex, uv).rgb;
	ALBEDO = escena;
	if (!activo) {
		ALPHA = 0.0;
	} else {
		vec2 px = grosor_px * (VIEWPORT_SIZE.y / 1080.0) / VIEWPORT_SIZE;
		float dc = lin_depth(uv, INV_PROJECTION_MATRIX);
		vec4 nc = nr(uv);
		float clase = nc.w;
		float borde = 0.0;
		if (clase < 0.95) {
			vec2 offs[4] = {vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y)};
			float umbral_d = clase < 0.85 ? umbral_profundidad : umbral_profundidad_follaje;
			for (int i = 0; i < 4; i++) {
				vec2 q = uv + offs[i];
				float dn = lin_depth(q, INV_PROJECTION_MATRIX);
				// solo el lado cercano dibuja la línea (sin líneas dobles)
				float salto = (dn - dc) / max(dc, 0.01);
				borde = max(borde, smoothstep(umbral_d, umbral_d * 1.6, salto));
				if (clase < 0.85) {
					vec4 nn = nr(q);
					if (nn.w < 0.85) {
						float dn_n = 1.0 - dot(nc.xyz, nn.xyz);
						borde = max(borde, smoothstep(umbral_normal, umbral_normal * 1.4, dn_n) * 0.8);
					}
				}
			}
		}
		float fade = 1.0 - smoothstep(distancia_ini, distancia_fin, dc);
		float a = borde * fade * opacidad;
		ALBEDO = escena * oscurecer * tinte_linea * 2.4;
		ALPHA = a;
	}
}
