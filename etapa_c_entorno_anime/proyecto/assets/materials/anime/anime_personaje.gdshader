// Material anime de personaje: color base (textura × tinte), sombra teñida por bandas, brillo
// especular estilizado y luz de borde. Sin mapa normal por defecto: el relieve fino rompería las
// bandas en manchas. 'pintado' toma la textura de un nivel de mip más alto para aplanar el ruido
// de las texturas horneadas sin cambiar el modelo (los personajes conservan malla, esqueleto y pesos).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

#include "res://assets/materials/anime/anime_luz.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 color_base : source_color = vec4(1.0);
uniform vec3 tinte = vec3(1.0);                  // aldeanos: tinte por personaje
uniform float pintado : hint_range(0.0, 4.0) = 0.0;
uniform float saturacion : hint_range(0.0, 2.0) = 1.0;
uniform float brillo_propio : hint_range(0.0, 2.0) = 0.0;   // ojos: algo de luz propia
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform bool usar_normal = false;
uniform float mascara_contorno : hint_range(0.0, 1.0) = 0.6; // ROUGHNESS: < 0.95 = admite contorno por normales

void fragment() {
	vec4 c = textureLod(albedo_tex, UV, pintado) * color_base;
	if (pintado <= 0.0) {
		c = texture(albedo_tex, UV) * color_base;
	}
	vec3 col = c.rgb * tinte;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturacion), vec3(0.0));
	ALBEDO = col;
	EMISSION = col * brillo_propio;
	if (usar_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = 0.4;
	}
	ROUGHNESS = mascara_contorno;
}
