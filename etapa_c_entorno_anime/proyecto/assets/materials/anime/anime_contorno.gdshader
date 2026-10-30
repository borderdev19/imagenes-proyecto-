// Contorno de personaje por casco invertido (se usa como next_pass del material anime, así el
// destello de daño sigue usando material_overlay). Grosor constante en píxeles, que se adelgaza
// con la distancia; color tomado de la propia textura oscurecida, no negro puro.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, skip_vertex_transform;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 color_base : source_color = vec4(1.0);
uniform vec3 tinte = vec3(1.0);
uniform float grosor_px : hint_range(0.0, 8.0) = 2.2;     // a 1080 p de alto
uniform float oscurecer : hint_range(0.0, 1.0) = 0.32;     // color de línea = textura × oscurecer
uniform vec3 color_linea : source_color = vec3(0.16, 0.1, 0.12);
uniform float mezcla_textura : hint_range(0.0, 1.0) = 0.7; // 0 = color_linea fijo
uniform float distancia_plena = 2.5;                       // metros: grosor completo hasta aquí
uniform float distancia_fin = 16.0;                        // metros: sin contorno a partir de aquí
uniform bool activo = true;

varying float v_fade;

void vertex() {
	vec4 vpos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 vn = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * vpos;
	vec2 nclip = (PROJECTION_MATRIX * vec4(vn, 0.0)).xy;
	float len = length(nclip);
	nclip = len > 1e-5 ? nclip / len : vec2(0.0);
	float d = -vpos.z;
	v_fade = 1.0 - smoothstep(distancia_plena, distancia_fin, d);
	float px = activo ? grosor_px * (VIEWPORT_SIZE.y / 1080.0) * mix(0.15, 1.0, v_fade) : 0.0;
	clip.xy += nclip * px * 2.0 / VIEWPORT_SIZE * clip.w;
	// un poco hacia atrás para no tapar detalles finos del frente
	clip.z -= 0.0004 * clip.w;
	POSITION = clip;
	VERTEX = vpos.xyz;
	NORMAL = vn;
}

void fragment() {
	if (!activo || v_fade <= 0.0) {
		discard;
	}
	vec3 t = texture(albedo_tex, UV).rgb * color_base.rgb * tinte;
	ALBEDO = mix(color_linea, t * oscurecer, mezcla_textura);
}
