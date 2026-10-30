class_name EntornoSelva
extends RefCounted
## Etapa C del estilo anime: piezas nuevas del entorno selvático, creadas en memoria (sin tocar
## ningún recurso original). Suelo con parches de color por vértice, masas de copa volumétricas y
## rocas estilizadas con relieve suave. Las funciones son estáticas y no dependen de la escena.

const SH_TERRENO := preload("res://assets/materials/anime/anime_terreno.gdshader")

## Parches del suelo: musgo, hierba, hojarasca, tierra y humedad.
const PALETA := {
	"musgo": Color(0.11, 0.3, 0.1),
	"hierba": Color(0.24, 0.41, 0.13),
	"hojarasca": Color(0.3, 0.24, 0.1),
	"tierra": Color(0.34, 0.26, 0.13),
	"humedo": Color(0.08, 0.23, 0.18),
}


## Material anime del suelo. Usa la misma familia de iluminación que el resto del estilo.
static func material_terreno(p := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_TERRENO
	m.resource_name = "anime:terreno"
	var sh := EstiloAnime.SOMBRA
	m.set_shader_parameter("sombra_color", Vector3(sh.r, sh.g, sh.b))
	m.set_shader_parameter("sombra_fuerza", float(p.get("sombra_fuerza", 0.6)))
	m.set_shader_parameter("bandas", 2)
	m.set_shader_parameter("umbral_sombra", 0.08)
	m.set_shader_parameter("suavizado", 0.035)
	m.set_shader_parameter("especular_fuerza", 0.0)
	m.set_shader_parameter("borde_fuerza", 0.0)
	m.set_shader_parameter("saturacion", float(p.get("saturacion", 1.08)))
	m.set_shader_parameter("detalle", float(p.get("detalle", 0.25)))
	m.set_shader_parameter("mascara_contorno", EstiloAnime.MASCARA_SOLIDO)
	return m


## Malla del suelo: cuadrícula de 'size' metros con 'res' subdivisiones por lado, colores por parches
## y un relieve muy suave (el jugador sigue caminando sobre un plano visualmente natural).
static func malla_terreno(size: float, res: int, semilla: int) -> ArrayMesh:
	var n1 := FastNoiseLite.new()
	n1.seed = semilla
	n1.frequency = 0.05
	var n2 := FastNoiseLite.new()
	n2.seed = semilla + 11
	n2.frequency = 0.16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paso := size / float(res)
	var origen := -size * 0.5
	for i in res:
		for j in res:
			for k in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				var x: float = origen + k[0] * paso
				var z: float = origen + k[1] * paso
				var v := Vector3(x, n1.get_noise_2d(x, z) * 0.12 + n2.get_noise_2d(x, z) * 0.04, z)
				st.set_uv(Vector2(x, z) * 0.1)
				st.set_color(_color_parche(n1.get_noise_2d(x, z), n2.get_noise_2d(x, z)))
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func _color_parche(a: float, b: float) -> Color:
	var c: Color = PALETA["hierba"].lerp(PALETA["musgo"], smoothstep(-0.3, 0.25, a))
	c = c.lerp(PALETA["humedo"], smoothstep(0.2, 0.45, -a) * 0.7)
	c = c.lerp(PALETA["hojarasca"], smoothstep(0.12, 0.3, b) * 0.85)
	c = c.lerp(PALETA["tierra"], smoothstep(0.32, 0.48, -b) * 0.45)
	return c


## Roca estilizada: esfera deformada con relieve de dos escalas, aplastada y apoyada en el suelo
## (la base queda en y = 0 con el origen de la malla en su centro).
static func roca(semilla: int, radio: float) -> ArrayMesh:
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 0.9
	return _esfera(28, 14, func(d: Vector3) -> Vector3:
		var r := radio * (1.0 + nz.get_noise_3d(d.x * 1.3, d.y * 1.3, d.z * 1.3) * 0.2 + nz.get_noise_3d(d.x * 3.6, d.y * 3.6, d.z * 3.6) * 0.05)
		var p := d * r
		p.y = p.y * 0.62 if p.y > 0.0 else p.y * 0.2
		return p + Vector3(0, radio * 0.12, 0))


## Masa de copa: esfera irregular, más ancha que alta, con lóbulos que rompen la silueta.
static func copa(semilla: int, radio: float) -> ArrayMesh:
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 0.5
	return _esfera(40, 20, func(d: Vector3) -> Vector3:
		var lobulo := nz.get_noise_3d(d.x * 2.4, d.y * 2.4, d.z * 2.4) * 0.24 + nz.get_noise_3d(d.x * 6.0, d.y * 6.0, d.z * 6.0) * 0.03
		var p := d * radio * (1.0 + lobulo)
		p.y *= 0.82
		return p)


## Esfera parametrizada por una función de deformación. Los triángulos se orientan hacia fuera
## para que la cara visible sea la exterior con cull_back (Godot toma como cara frontal el orden
## horario visto desde fuera).
static func _esfera(segmentos: int, anillos: int, deformar: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	for i in anillos + 1:
		var fila := []
		var th := PI * float(i) / float(anillos)
		for j in segmentos + 1:
			var ph := TAU * float(j) / float(segmentos)
			var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			fila.append(deformar.call(d))
		pts.append(fila)
	for i in anillos:
		for j in segmentos:
			_tri(st, pts[i][j], pts[i + 1][j], pts[i + 1][j + 1])
			_tri(st, pts[i][j], pts[i + 1][j + 1], pts[i][j + 1])
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b - a).cross(c - a).dot(a + b + c) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
