// Luciérnagas (Etapa C, revisión C3): puntos de luz que se orientan a la cámara, parpadean y flotan.
// Solo se ven de noche ('intensidad' la fija el script según la hora). Aditivo y sin sombra; el
// glow del entorno anime les da el halo.
// COLOR.r = fase del parpadeo, COLOR.g = fase del vuelo; UV = esquina de la tarjeta (-1..1).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 color_luz : source_color = vec3(0.75, 1.0, 0.45);
uniform float intensidad : hint_range(0.0, 4.0) = 0.0;
uniform float tamano = 0.07;

varying float brillo;

void vertex() {
	float t = TIME * 0.6 + COLOR.g * 40.0;
	vec3 vuelo = vec3(sin(t) * 0.5, sin(t * 1.7) * 0.25, cos(t * 0.8) * 0.5);
	vec4 centro = MODELVIEW_MATRIX * vec4(VERTEX + vuelo, 1.0);
	centro.xy += UV * tamano;
	POSITION = PROJECTION_MATRIX * centro;
	float parpadeo = 0.5 + 0.5 * sin(TIME * 2.3 + COLOR.r * 31.0);
	brillo = smoothstep(0.25, 0.9, parpadeo);
}

void fragment() {
	float d = length(UV);
	float a = smoothstep(1.0, 0.0, d);
	ALBEDO = color_luz * a * a * brillo * intensidad;
	ALPHA = 1.0;
}
