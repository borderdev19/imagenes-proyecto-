class_name EstiloAnime
extends RefCounted
## Sistema de materiales del estilo anime (Etapa B). Fábrica de materiales separada por familias:
## personaje (con contorno de casco invertido), entorno sólido, follaje; más el perfil de entorno
## (luz, sombras, color) y el contorno de pantalla. Los shaders viven en assets/materials/anime/.
## Nada de esto toca los recursos originales: los materiales se crean en memoria y los originales
## de cada malla se guardan en la meta "mat_v13" para volver al estilo pictórico.

const DIR := "res://assets/materials/anime/"
const SH_PERSONAJE := preload("res://assets/materials/anime/anime_personaje.gdshader")
const SH_CONTORNO := preload("res://assets/materials/anime/anime_contorno.gdshader")
const SH_ENTORNO := preload("res://assets/materials/anime/anime_entorno.gdshader")
const SH_FOLLAJE := preload("res://assets/materials/anime/anime_follaje.gdshader")
const SH_POST := preload("res://assets/materials/anime/anime_contorno_post.gdshader")

## Clases para el contorno de pantalla (se escriben en ROUGHNESS, ver anime_contorno_post).
const MASCARA_SOLIDO := 0.6
const MASCARA_FOLLAJE := 0.9
const MASCARA_PERSONAJE := 1.0

## Tono de sombra común: violeta azulado frío, como en la animación japonesa (nunca negro).
const SOMBRA := Color(0.5, 0.46, 0.68)
const SOMBRA_PIEL := Color(0.78, 0.5, 0.52)


static func forward_plus() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


static func contornos_activos() -> bool:
	return Ajustes.contornos


# ------------------------------------------------------------------ personajes
## Material anime equivalente a un material importado del GLB (color, textura y si es metal u ojo).
## El contorno va en next_pass: material_overlay queda libre para el destello de daño.
static func material_personaje(orig: Material, tinte := Color(1, 1, 1)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_PERSONAJE
	m.resource_name = "anime:" + (String(orig.resource_name) if orig else "")
	var tex: Texture2D = null
	var col := Color(1, 1, 1)
	var metal := 0.0
	var rough := 1.0
	if orig is BaseMaterial3D:
		var b := orig as BaseMaterial3D
		tex = b.albedo_texture
		col = b.albedo_color
		metal = b.metallic
		rough = b.roughness
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("color_base", col)
	m.set_shader_parameter("tinte", Vector3(tinte.r, tinte.g, tinte.b))
	m.set_shader_parameter("sombra_color", Vector3(SOMBRA.r, SOMBRA.g, SOMBRA.b))
	m.set_shader_parameter("sombra_fuerza", 0.62)
	m.set_shader_parameter("bandas", 3)
	m.set_shader_parameter("umbral_sombra", 0.05)
	m.set_shader_parameter("umbral_luz", 0.62)
	m.set_shader_parameter("tono_medio", 0.86)
	m.set_shader_parameter("suavizado", 0.03)
	m.set_shader_parameter("borde_fuerza", 0.55)
	m.set_shader_parameter("borde_ancho", 0.28)
	m.set_shader_parameter("especular_fuerza", 0.18)
	m.set_shader_parameter("especular_tamano", 0.2)
	m.set_shader_parameter("pintado", 1.0)
	m.set_shader_parameter("mascara_contorno", MASCARA_PERSONAJE)
	var nombre := String(orig.resource_name).to_lower() if orig else ""
	if metal > 0.5:
		# metal anime: oscuro con un brillo grande y nítido
		m.set_shader_parameter("especular_fuerza", 1.4)
		m.set_shader_parameter("especular_tamano", 0.45 if rough < 0.35 else 0.3)
		m.set_shader_parameter("sombra_fuerza", 0.4)
	if nombre.contains("ojo"):
		m.set_shader_parameter("especular_fuerza", 1.6)
		m.set_shader_parameter("especular_tamano", 0.15)
		m.set_shader_parameter("brillo_propio", 0.2)
		m.set_shader_parameter("pintado", 0.0)
		m.set_shader_parameter("borde_fuerza", 0.0)
	if not nombre.contains("ojo"):
		m.next_pass = _contorno_para(m)
	return m


static func _contorno_para(m: ShaderMaterial) -> ShaderMaterial:
	var o := ShaderMaterial.new()
	o.shader = SH_CONTORNO
	o.resource_name = "anime:contorno"
	o.set_shader_parameter("albedo_tex", m.get_shader_parameter("albedo_tex"))
	o.set_shader_parameter("color_base", m.get_shader_parameter("color_base"))
	o.set_shader_parameter("tinte", m.get_shader_parameter("tinte"))
	o.set_shader_parameter("activo", contornos_activos())
	return o


## Aplica el estilo anime a todas las mallas de un personaje (Pollo Amarillo, Pollo Negro, aldeanos).
## Modelo, esqueleto, pesos y animaciones no cambian: solo los materiales de superficie.
static func aplicar_a_personaje(root: Node, tinte := Color(1, 1, 1)) -> void:
	for mi in _mallas(root):
		if not mi.has_meta("mat_v13"):
			var orig := []
			for i in mi.get_surface_override_material_count():
				orig.append(mi.get_surface_override_material(i))
			mi.set_meta("mat_v13", orig)
		for i in mi.get_surface_override_material_count():
			var base: Material = mi.mesh.surface_get_material(i) if mi.mesh else null
			mi.set_surface_override_material(i, material_personaje(base, tinte))


## Devuelve un personaje a sus materiales v13 (estilo pictórico).
static func restaurar_personaje(root: Node) -> void:
	for mi in _mallas(root):
		if mi.has_meta("mat_v13"):
			var orig: Array = mi.get_meta("mat_v13")
			for i in mini(orig.size(), mi.get_surface_override_material_count()):
				mi.set_surface_override_material(i, orig[i])


static func _mallas(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		out.append(root as MeshInstance3D)
	for c in root.find_children("*", "MeshInstance3D", true, false):
		out.append(c as MeshInstance3D)
	return out


## Activa o desactiva los contornos de casco invertido de un personaje ya convertido.
static func contorno_personaje(root: Node, activo: bool) -> void:
	for mi in _mallas(root):
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m and m.next_pass is ShaderMaterial:
				(m.next_pass as ShaderMaterial).set_shader_parameter("activo", activo)


# ------------------------------------------------------------------ entorno
## Material sólido de entorno. p: {tex, color, uv, escala, detalle, pintado, musgo, ...}
static func material_entorno(p: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_ENTORNO
	m.resource_name = "anime:" + String(p.get("nombre", "entorno"))
	if p.has("tex"):
		m.set_shader_parameter("albedo_tex", p["tex"])
	var c: Color = p.get("color", Color(0.55, 0.42, 0.3))
	m.set_shader_parameter("color_plano", Vector3(c.r, c.g, c.b))
	m.set_shader_parameter("usar_uv", bool(p.get("uv", false)))
	m.set_shader_parameter("escala", float(p.get("escala", 0.4)))
	m.set_shader_parameter("detalle", float(p.get("detalle", 0.45)))
	m.set_shader_parameter("pintado", float(p.get("pintado", 2.5)))
	m.set_shader_parameter("musgo", float(p.get("musgo", 0.0)))
	m.set_shader_parameter("doble_cara", bool(p.get("doble_cara", false)))
	m.set_shader_parameter("sombra_color", Vector3(SOMBRA.r, SOMBRA.g, SOMBRA.b))
	m.set_shader_parameter("sombra_fuerza", float(p.get("sombra_fuerza", 0.6)))
	m.set_shader_parameter("bandas", int(p.get("bandas", 2)))
	m.set_shader_parameter("umbral_sombra", float(p.get("umbral", 0.08)))
	m.set_shader_parameter("suavizado", 0.035)
	m.set_shader_parameter("especular_fuerza", float(p.get("especular", 0.0)))
	m.set_shader_parameter("borde_fuerza", float(p.get("borde", 0.0)))
	m.set_shader_parameter("mascara_contorno", MASCARA_SOLIDO)
	return m


## Material de follaje: copas (viento por color R) o sotobosque (viento por altura).
## centro: centro local de la masa de hojas, para las normales esféricas.
static func material_follaje(p: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_FOLLAJE
	m.resource_name = "anime:" + String(p.get("nombre", "follaje"))
	if p.has("tex"):
		m.set_shader_parameter("albedo_tex", p["tex"])
	var c: Color = p.get("color", Color(0.36, 0.62, 0.24))
	var t: Color = p.get("punta", c.lightened(0.3))
	m.set_shader_parameter("color_hoja", Vector3(c.r, c.g, c.b))
	m.set_shader_parameter("color_punta", Vector3(t.r, t.g, t.b))
	m.set_shader_parameter("corte_alfa", float(p.get("corte", 0.42)))
	m.set_shader_parameter("viento_modo", int(p.get("viento_modo", 0)))
	m.set_shader_parameter("viento", float(p.get("viento", 0.15)))
	m.set_shader_parameter("normales_esfericas", float(p.get("esfericas", 0.75)))
	m.set_shader_parameter("centro_copa", p.get("centro", Vector3(0, 1, 0)))
	m.set_shader_parameter("detalle", float(p.get("detalle", 0.35)))
	var sh := Color(0.3, 0.38, 0.6)
	m.set_shader_parameter("sombra_color", Vector3(sh.r, sh.g, sh.b))
	m.set_shader_parameter("sombra_fuerza", 0.55)
	m.set_shader_parameter("bandas", 2)
	m.set_shader_parameter("umbral_sombra", float(p.get("umbral", 0.1)))
	m.set_shader_parameter("suavizado", 0.05)
	m.set_shader_parameter("translucidez", float(p.get("translucidez", 0.2)))
	m.set_shader_parameter("mascara_contorno", MASCARA_FOLLAJE)
	return m


## Centro local de cada superficie de las mallas de un GLB, leído de los límites (min/max) que el
## propio glTF guarda por primitiva: no hace falta leer los vértices (lento con mallas grandes).
## Devuelve {nombre_de_nodo: [centro_superficie_0, centro_superficie_1, ...]}.
static var _limites := {}


static func centros_glb(path: String) -> Dictionary:
	if _limites.has(path):
		return _limites[path]
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	f.seek(12)
	var n := f.get_32()
	f.get_32()
	var j = JSON.parse_string(f.get_buffer(n).get_string_from_utf8())
	f.close()
	if not (j is Dictionary):
		return out
	var acc: Array = j.get("accessors", [])
	var meshes: Array = j.get("meshes", [])
	for node in j.get("nodes", []):
		if not node.has("mesh"):
			continue
		var centros := []
		for prim in meshes[int(node["mesh"])]["primitives"]:
			var a: Dictionary = acc[int(prim["attributes"]["POSITION"])]
			var lo: Array = a.get("min", [0, 0, 0])
			var hi: Array = a.get("max", [0, 0, 0])
			centros.append(Vector3((lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5, (lo[2] + hi[2]) * 0.5))
		out[String(node["name"])] = centros
	_limites[path] = out
	return out


# ------------------------------------------------------------------ luz, color y contorno de pantalla
## Perfil de entorno anime: colores vivos sin quemar, sombras legibles (ambiente alto y frío),
## oclusión suave, niebla de profundidad azulada y resplandor contenido. No toca el entorno v13:
## se aplica a un Environment propio de la escena que lo pida.
static func configurar_entorno(env: Environment) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.94
	env.tonemap_white = 4.5
	env.ambient_light_energy = 0.55
	env.ambient_light_sky_contribution = 0.55
	env.ambient_light_color = Color(0.62, 0.68, 0.86)
	env.ssao_enabled = forward_plus()
	env.ssao_radius = 0.8
	env.ssao_intensity = 0.9
	env.ssao_power = 1.2
	env.ssao_light_affect = 0.0
	env.ssao_ao_channel_affect = 0.0
	env.ssil_enabled = false
	env.ssr_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.03
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.08
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 30.0
	env.fog_depth_end = 160.0
	env.fog_depth_curve = 1.4
	env.fog_density = 0.3
	env.fog_light_color = Color(0.66, 0.78, 0.92)
	env.fog_sky_affect = 0.25
	env.fog_aerial_perspective = 0.35
	env.volumetric_fog_enabled = false
	env.set_meta("ssr_base", false)
	env.set_meta("niebla_base", false)


## Sol con sombras nítidas pero sin dientes de sierra en el borde de las bandas.
static func configurar_sol(sun: DirectionalLight3D) -> void:
	sun.shadow_enabled = true
	sun.light_angular_distance = 0.35
	sun.shadow_blur = 0.6
	sun.shadow_opacity = 1.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.6
	sun.directional_shadow_blend_splits = true


## Contorno de pantalla para el escenario (solo Forward+). Devuelve null en Compatibility.
static func crear_contorno_post(cam: Camera3D) -> MeshInstance3D:
	if not forward_plus():
		return null
	var q := MeshInstance3D.new()
	q.name = "ContornoAnime"
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	q.mesh = qm
	q.extra_cull_margin = 16384.0
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SH_POST
	m.set_shader_parameter("activo", contornos_activos())
	q.material_override = m
	cam.add_child(q)
	q.position = Vector3(0, 0, -0.5)
	return q


## Color medio de una textura (para el color plano de un material pintado).
static func color_medio(tex: Texture2D, defecto := Color(0.5, 0.5, 0.5)) -> Color:
	if tex == null:
		return defecto
	var img := tex.get_image()
	if img == null:
		return defecto
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(8, 8, Image.INTERPOLATE_BILINEAR)
	var acc := Color(0, 0, 0, 0)
	var n := 0.0
	for y in 8:
		for x in 8:
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				acc += c
				n += 1.0
	if n < 1.0:
		return defecto
	acc /= n
	return Color(acc.r, acc.g, acc.b)
