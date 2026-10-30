class_name PruebaAnime
extends Node3D
## Laboratorio del estilo anime (Etapa B): esferas, madera, roca, follaje y los dos pollos actuales
## bajo distintas horas, ángulos de sol y encuadres, con el estilo anime o el pictórico v13 para
## comparar. No modifica ningún recurso: los materiales se crean en memoria.
##
## Teclas: Tab estilo · 1-8 encuadre · H hora · L gira el sol · O contornos · Esc menú.
## Capturas automáticas:
##   godot --path . res://scenes/pruebas/PruebaAnime.tscn -- --capturas=/ruta [--plan=completo|basico]

const ESCENA := "res://scenes/pruebas/PruebaAnime.tscn"
const LIB_GLB := "res://assets/mundo3d/biblioteca.glb"
const TEX := "res://assets/mundo3d/tex/"
const VEG := "res://assets/mundo3d/veg/"

## encuadre: [posición, mira, fov]
const PLANOS := {
	"general": [Vector3(0.0, 3.2, 9.5), Vector3(0.0, 1.0, -1.0), 55.0],
	"amarillo_cara": [Vector3(-1.25, 1.75, 2.45), Vector3(-1.2, 1.62, 1.0), 32.0],
	"negro_cara": [Vector3(1.35, 1.85, 2.5), Vector3(1.25, 1.72, 1.0), 32.0],
	"personajes": [Vector3(0.0, 1.35, 5.2), Vector3(0.0, 1.0, 1.0), 42.0],
	"esferas": [Vector3(0.0, 1.6, 3.0), Vector3(0.0, 0.6, -2.2), 50.0],
	"madera_roca": [Vector3(-4.6, 1.9, 1.6), Vector3(-5.2, 0.6, -2.4), 52.0],
	"follaje": [Vector3(4.2, 2.2, 3.4), Vector3(5.6, 2.2, -3.5), 60.0],
	"arbol": [Vector3(2.0, 2.4, 9.0), Vector3(6.0, 6.5, -6.0), 62.0],
}
const HORAS := [9.0, 13.0, 16.5, 18.2, 21.0]
## ángulos de sol de prueba: [nombre, elevación°, azimut relativo a la cámara general°]
const SOLES := [["frontal", 35.0, 180.0], ["lateral", 25.0, 90.0], ["contraluz", 18.0, 0.0], ["cenital", 78.0, 150.0], ["rasante", 6.0, 250.0]]

var estilo := Ajustes.ESTILO_ANIME
var hora := 16.5
var sol_idx := -1               # -1 = el del ciclo día-noche
var plano := "general"
var sun: DirectionalLight3D
var env_anime: Environment
var env_v13: Environment
var we: WorldEnvironment
var ciclo: CicloDia
var cam: Camera3D
var look: CinematicLook
var contorno_post: MeshInstance3D
var amarillo: ChickenVisual
var negro: ChickenVisual
var _objetos: Array = []        # [MeshInstance3D, superficie, material v13, material anime]
var _info: Label
var capturas_dir := ""
var plan := "completo"
var stats := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			capturas_dir = a.substr(11)
		elif a.begins_with("--plan="):
			plan = a.substr(7)
		elif a.begins_with("--estilo="):
			estilo = Ajustes.ESTILO_PICTORICO if a.substr(9) == "v13" else Ajustes.ESTILO_ANIME
	_entorno()
	_camara()
	_suelo()
	_esferas()
	_madera_roca()
	_follaje()
	_personajes()
	_ui()
	aplicar_estilo(estilo)
	set_plano(plano)
	if capturas_dir != "":
		_capturar.call_deferred()


# ------------------------------------------------------------------ montaje
func _entorno() -> void:
	we = WorldEnvironment.new()
	env_v13 = Environment.new()
	env_v13.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_v13.fog_enabled = true
	env_v13.fog_density = 0.0035
	env_v13.fog_aerial_perspective = 0.6
	env_v13.fog_sky_affect = 0.4
	CinematicLook.setup_environment(env_v13, "mundo")
	env_anime = Environment.new()
	EstiloAnime.configurar_entorno(env_anime)
	we.environment = env_anime
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.name = "Sol"
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	ciclo = CicloDia.new()
	add_child(ciclo)
	ciclo.setup(sun, env_anime, null)
	# el cielo es el mismo recurso para los dos entornos
	env_v13.background_mode = Environment.BG_SKY
	env_v13.sky = env_anime.sky
	env_v13.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_v13.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	look = CinematicLook.new()
	look.name = "FiltroCinematico"
	add_child(look)


func _camara() -> void:
	cam = Camera3D.new()
	cam.far = 1500.0
	add_child(cam)
	cam.current = true
	contorno_post = EstiloAnime.crear_contorno_post(cam)


func _registrar(mi: MeshInstance3D, surf: int, v13: Material, anime: Material) -> void:
	_objetos.append([mi, surf, v13, anime])


func _malla(mesh: Mesh, pos: Vector3, rot := Vector3.ZERO, escala := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = Vector3.ONE * escala
	add_child(mi)
	return mi


func _tex(n: String) -> Texture2D:
	return load(TEX + n) if ResourceLoader.exists(TEX + n) else null


func _suelo() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	var mi := _malla(pm, Vector3.ZERO)
	var v13 := MaterialesMundo.get_material("Empedrado")
	var t := _tex("suelo_musgo_col.jpg")
	var an := EstiloAnime.material_entorno({"nombre": "suelo", "tex": t, "color": Color(0.24, 0.4, 0.16), "escala": 0.12, "detalle": 0.9, "pintado": 2.0})
	_registrar(mi, 0, v13, an)


func _esferas() -> void:
	var colores := [["blanco", Color(0.92, 0.92, 0.9), 0.0], ["piel", Color(0.98, 0.82, 0.62), 0.0], ["rojo", Color(0.82, 0.16, 0.12), 0.0],
		["jade", Color(0.18, 0.62, 0.45), 0.0], ["azul", Color(0.22, 0.4, 0.78), 0.0], ["metal", Color(0.62, 0.63, 0.66), 1.0]]
	var sm := SphereMesh.new()
	sm.radius = 0.42
	sm.height = 0.84
	sm.radial_segments = 64
	sm.rings = 32
	for i in colores.size():
		var e: Array = colores[i]
		var mi := _malla(sm, Vector3(-2.5 + i * 1.0, 0.42, -2.2))
		mi.name = "Esfera_" + e[0]
		var v := StandardMaterial3D.new()
		v.albedo_color = e[1]
		v.metallic = e[2]
		v.roughness = 0.3 if e[2] > 0.5 else 0.7
		v.resource_name = "Metal_Plateado" if e[2] > 0.5 else "esfera"
		# las esferas usan el material de personaje: es la referencia de bandas, sombra y brillo
		var an := EstiloAnime.material_personaje(v)
		_registrar(mi, 0, v, an)
	stats["esferas"] = colores.size()


func _madera_roca() -> void:
	# tronco caído (corteza), tablones (madera) y una caja de mimbre
	var cy := CylinderMesh.new()
	cy.top_radius = 0.32
	cy.bottom_radius = 0.36
	cy.height = 2.6
	cy.radial_segments = 24
	var tronco := _malla(cy, Vector3(-5.6, 0.34, -1.2), Vector3(0, 25, 90))
	_registrar(tronco, 0, MaterialesMundo.get_material("Corteza"),
		EstiloAnime.material_entorno({"nombre": "corteza", "tex": _tex("corteza_col.jpg"), "color": Color(0.46, 0.33, 0.24), "escala": 0.5, "detalle": 0.6, "pintado": 2.0, "musgo": 0.25}))
	var bx := BoxMesh.new()
	bx.size = Vector3(1.8, 0.12, 0.34)
	for k in 3:
		var tab := _malla(bx, Vector3(-4.2, 0.06 + k * 0.12, -2.6 + k * 0.05), Vector3(0, -20 + k * 9, 0))
		_registrar(tab, 0, MaterialesMundo.get_material("Tablon"),
			EstiloAnime.material_entorno({"nombre": "tablon", "tex": _tex("tablon_col.jpg"), "color": Color(0.62, 0.45, 0.3), "escala": 0.55, "detalle": 0.55, "pintado": 1.5}))
	var cesta := _malla(BoxMesh.new(), Vector3(-3.4, 0.35, -0.6), Vector3(0, 30, 0), 0.7)
	_registrar(cesta, 0, MaterialesMundo.get_material("Tejido_Nido"),
		EstiloAnime.material_entorno({"nombre": "mimbre", "tex": _tex("mimbre_nido_col.jpg"), "color": Color(0.76, 0.6, 0.38), "uv": true, "escala": 1.5, "detalle": 0.7, "pintado": 1.0}))
	# rocas de la biblioteca del mundo (escaneos CC0 que se estilizarán en Blender en la Etapa C)
	var lib := _biblioteca()
	for e in [["V_boulder_01_0", Vector3(-6.4, 0.0, -3.6), 1.6], ["V_rock_moss_set_01_0", Vector3(-3.6, 0.0, -4.6), 0.9], ["V_root_cluster_01_0", Vector3(-7.4, 0.0, -1.0), 0.8]]:
		var mesh: Mesh = lib.get(e[0])
		if mesh == null:
			continue
		var mi := _malla(mesh, e[1], Vector3(0, 40, 0), e[2])
		for s in mesh.get_surface_count():
			var orig := mesh.surface_get_material(s)
			var nombre := String(orig.resource_name) if orig else ""
			var v13 := MaterialesMundo.plant_material(nombre)
			var t: Texture2D = null
			if v13 is BaseMaterial3D:
				t = (v13 as BaseMaterial3D).albedo_texture
			var base := EstiloAnime.color_medio(t, Color(0.5, 0.48, 0.42))
			var es_raiz := nombre.begins_with("root")
			var an := EstiloAnime.material_entorno({"nombre": nombre, "tex": t, "uv": true, "escala": 1.0, "color": base.lerp(Color(0.55, 0.52, 0.5), 0.25) if not es_raiz else base,
				"detalle": 0.55, "pintado": 2.5, "musgo": 0.0 if es_raiz else 0.35})
			_registrar(mi, s, v13, an)
	stats["rocas"] = true


func _follaje() -> void:
	var lib := _biblioteca()
	for e in [["ArbolSelva_0", Vector3(7.5, 0.0, -7.0), 0.75], ["V_fern_02_0", Vector3(3.6, 0.0, -1.6), 2.4], ["V_fern_02_1", Vector3(5.0, 0.0, -0.6), 2.2],
			["Monstera_0", Vector3(4.6, 0.0, -2.9), 1.2], ["V_shrub_01_0", Vector3(6.4, 0.0, -2.2), 1.3], ["Palma_0", Vector3(9.5, 0.0, -2.5), 0.55],
			["V_grass_medium_01_0", Vector3(2.6, 0.0, -0.2), 1.2]]:
		var mesh: Mesh = lib.get(e[0])
		if mesh == null:
			continue
		var mi := _malla(mesh, e[1], Vector3(0, 20, 0), e[2])
		mi.name = e[0]
		for s in mesh.get_surface_count():
			var orig := mesh.surface_get_material(s)
			var nombre := String(orig.resource_name) if orig else ""
			var v13: Material
			var an: Material
			if MaterialesMundo.PBR_TABLE.has(nombre) or nombre.begins_with("Hojas") or nombre in ["Hiedra", "Liana"]:
				v13 = MaterialesMundo.get_material(nombre, orig)
			else:
				v13 = MaterialesMundo.plant_material(nombre)
			an = _anime_para_vegetal(nombre, v13, EstiloAnime.centros_glb(LIB_GLB).get(e[0], []), s)
			_registrar(mi, s, v13, an)
	stats["follaje"] = true


## Material anime de una superficie de la biblioteca según su material original.
func _anime_para_vegetal(nombre: String, v13: Material, centros: Array, s: int) -> Material:
	var centro: Vector3 = centros[s] if s < centros.size() else Vector3(0, 1, 0)
	match nombre:
		"Corteza":
			return EstiloAnime.material_entorno({"nombre": "corteza", "tex": _tex("corteza_col.jpg"), "color": Color(0.44, 0.33, 0.25), "escala": 0.38, "detalle": 0.55, "pintado": 2.0, "musgo": 0.2})
		"Liana":
			return EstiloAnime.material_entorno({"nombre": "liana", "color": Color(0.3, 0.36, 0.16), "detalle": 0.0})
		"Hojas_Dosel", "Hojas_Oscuras", "Hojas_Tropicales", "Hiedra", "Hojas_Rojas":
			var file: String = {"Hojas_Dosel": "hojas_dosel", "Hojas_Oscuras": "hojas_oscuras", "Hiedra": "hiedra", "Hojas_Rojas": "hojas_rojas", "Hojas_Tropicales": "hojas_tropicales"}[nombre]
			var c: Color = {"Hojas_Dosel": Color(0.22, 0.46, 0.2), "Hojas_Oscuras": Color(0.16, 0.36, 0.2), "Hiedra": Color(0.24, 0.46, 0.18),
				"Hojas_Rojas": Color(0.86, 0.3, 0.2), "Hojas_Tropicales": Color(0.26, 0.5, 0.2)}[nombre]
			return EstiloAnime.material_follaje({"nombre": nombre, "tex": _tex(file + ".webp"), "color": c, "punta": c.lightened(0.28),
				"corte": 0.5 if nombre == "Hojas_Tropicales" else 0.42, "viento": 0.12 if nombre == "Hojas_Tropicales" else 0.15, "centro": centro,
				"esfericas": 0.8 if nombre == "Hojas_Dosel" or nombre == "Hojas_Oscuras" else 0.45})
	# plantas CC0 del sotobosque
	var t: Texture2D = null
	var corte := 0.0
	if v13 is ShaderMaterial:
		t = (v13 as ShaderMaterial).get_shader_parameter("albedo_tex")
		corte = float((v13 as ShaderMaterial).get_shader_parameter("alpha_cut"))
	elif v13 is BaseMaterial3D:
		t = (v13 as BaseMaterial3D).albedo_texture
	var base := EstiloAnime.color_medio(t, Color(0.35, 0.55, 0.25))
	# verde más limpio y vivo a partir del color real de la planta
	# verde de selva limpio: se conserva el tono propio de cada planta, con saturación y valor contenidos
	var h := Color.from_hsv(clampf(base.h, 0.26, 0.36), clampf(base.s * 1.3, 0.5, 0.75), clampf(base.v * 0.85, 0.28, 0.45))
	return EstiloAnime.material_follaje({"nombre": nombre, "tex": t, "color": h, "punta": h.lightened(0.18), "corte": corte if corte > 0.0 else 0.3,
		"viento_modo": 1, "viento": 0.06, "centro": centro, "esfericas": 0.55, "detalle": 0.4})


var _lib_cache := {}


func _biblioteca() -> Dictionary:
	if not _lib_cache.is_empty():
		return _lib_cache
	if not ResourceLoader.exists(LIB_GLB):
		return _lib_cache
	var lib: Node = (load(LIB_GLB) as PackedScene).instantiate()
	for mi in lib.find_children("*", "MeshInstance3D", true, false):
		_lib_cache[String(mi.name)] = (mi as MeshInstance3D).mesh
	lib.free()
	return _lib_cache


func _personajes() -> void:
	amarillo = (load("res://scenes/characters/PolloAmarillo.tscn") as PackedScene).instantiate()
	add_child(amarillo)
	amarillo.position = Vector3(-1.2, 0.0, 1.0)
	amarillo.rotation_degrees = Vector3(0, 15, 0)
	negro = (load("res://scenes/characters/PolloNegro.tscn") as PackedScene).instantiate()
	add_child(negro)
	negro.position = Vector3(1.25, 0.0, 1.0)
	negro.rotation_degrees = Vector3(0, -15, 0)
	for c in [amarillo, negro]:
		c.add_child(CombatStage.make_blob_shadow(0.45))
	amarillo.play.call_deferred("idle", 0.0)
	negro.play.call_deferred("battle_idle", 0.0)


func _ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_info = Label.new()
	_info.position = Vector2(24, 18)
	_info.add_theme_font_size_override("font_size", 20)
	_info.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_info.add_theme_constant_override("outline_size", 6)
	layer.add_child(_info)
	_info.visible = capturas_dir == ""


# ------------------------------------------------------------------ estado
func aplicar_estilo(e: int) -> void:
	estilo = e
	var anime := e == Ajustes.ESTILO_ANIME
	for o in _objetos:
		var mi: MeshInstance3D = o[0]
		mi.set_surface_override_material(int(o[1]), o[3] if anime else o[2])
		# las esferas llevan el material de personaje: su contorno sigue la opción Contornos
		var am := o[3] as ShaderMaterial
		if am and am.next_pass is ShaderMaterial:
			(am.next_pass as ShaderMaterial).set_shader_parameter("activo", Ajustes.contornos)
	if anime:
		EstiloAnime.aplicar_a_personaje(amarillo)
		EstiloAnime.aplicar_a_personaje(negro)
		EstiloAnime.contorno_personaje(amarillo, Ajustes.contornos)
		EstiloAnime.contorno_personaje(negro, Ajustes.contornos)
		EstiloAnime.configurar_sol(sun)
	else:
		EstiloAnime.restaurar_personaje(amarillo)
		EstiloAnime.restaurar_personaje(negro)
		sun.light_angular_distance = 1.2
		sun.shadow_blur = 1.5
		sun.shadow_opacity = 0.92
		sun.shadow_bias = 0.1
		sun.shadow_normal_bias = 2.0
	we.environment = env_anime if anime else env_v13
	ciclo.env = we.environment
	if contorno_post:
		contorno_post.visible = anime
		(contorno_post.material_override as ShaderMaterial).set_shader_parameter("activo", Ajustes.contornos)
	# el filtro pictórico solo en el estilo v13
	look.visible = not anime
	set_hora(hora)


func set_hora(h: float) -> void:
	hora = h
	ciclo.set_hour(h)
	if estilo == Ajustes.ESTILO_ANIME:
		# ambiente más alto y frío: las sombras se leen como color, no como negro
		var e := we.environment
		e.ambient_light_energy = clampf(e.ambient_light_energy * 1.15, 0.32, 0.75)
		e.ambient_light_sky_contribution = 0.55
		e.fog_light_color = e.fog_light_color.lerp(Color(0.62, 0.74, 0.92), 0.5)
	_aplicar_sol()
	_refresh_info()


func set_sol(i: int) -> void:
	sol_idx = i
	set_hora(hora)


func _aplicar_sol() -> void:
	if sol_idx < 0:
		return
	var s: Array = SOLES[sol_idx]
	var elev := deg_to_rad(float(s[1]))
	# azimut relativo a la cámara general (que mira hacia -Z): 0 = sol detrás del sujeto (contraluz)
	var az := deg_to_rad(float(s[2]))
	var to_sun := Vector3(sin(az) * cos(elev), sin(elev), -cos(az) * cos(elev)).normalized()
	sun.look_at_from_position(Vector3.ZERO, -to_sun, Vector3.UP if absf(to_sun.y) < 0.99 else Vector3.FORWARD)
	if hora >= 20.0 or hora < 5.5:
		return
	sun.light_energy = maxf(sun.light_energy, 1.2)


func set_plano(n: String) -> void:
	if not PLANOS.has(n):
		return
	plano = n
	var p: Array = PLANOS[n]
	cam.fov = float(p[2])
	cam.look_at_from_position(p[0], p[1], Vector3.UP)
	# primeros planos: se encuadra la cabeza real (hueso "head") de cada pollo, de frente y algo de lado
	if n == "amarillo_cara" and amarillo:
		_plano_cara(amarillo, 1.0, 0.35)
	elif n == "negro_cara" and negro:
		_plano_cara(negro, 1.05, -0.35)
	_refresh_info()


func _plano_cara(c: Node3D, dist: float, lado: float) -> void:
	var sk: Skeleton3D = c.find_children("*", "Skeleton3D", true, false)[0] if c.find_children("*", "Skeleton3D", true, false).size() > 0 else null
	var cabeza := c.global_position + Vector3(0, 1.3, 0)
	if sk and sk.find_bone("head") >= 0:
		cabeza = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head"))).origin + Vector3(0, 0.16, 0)
	var frente := c.global_transform.basis.z.normalized()
	var derecha := c.global_transform.basis.x.normalized()
	var pos := cabeza + frente * dist + derecha * lado + Vector3(0, 0.05, 0)
	cam.fov = 34.0
	cam.look_at_from_position(pos, cabeza, Vector3.UP)


func _refresh_info() -> void:
	if _info == null:
		return
	var sol := "ciclo" if sol_idx < 0 else String(SOLES[sol_idx][0])
	_info.text = "LABORATORIO ANIME · estilo: %s · hora %.1f · sol: %s · plano: %s · contornos: %s\nTab estilo · 1-8 plano · H hora · L sol · O contornos · Esc menú" % [
		Ajustes.ESTILOS[estilo], hora, sol, plano, "sí" if Ajustes.contornos else "no"]


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := (ev as InputEventKey).keycode
	match k:
		KEY_TAB:
			aplicar_estilo(1 - estilo)
		KEY_H:
			set_hora(HORAS[(HORAS.find(hora) + 1) % HORAS.size()] if HORAS.has(hora) else HORAS[0])
		KEY_L:
			set_sol(sol_idx + 1 if sol_idx + 1 < SOLES.size() else -1)
		KEY_O:
			Ajustes.set_valor("contornos", 0 if Ajustes.contornos else 1)
			aplicar_estilo(estilo)
		KEY_ESCAPE:
			SceneRouter.change_scene(GameState.SCENE_MENU)
		_:
			if k >= KEY_1 and k <= KEY_8:
				set_plano(PLANOS.keys()[k - KEY_1])


# ------------------------------------------------------------------ capturas automáticas
func _shot(nombre: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_jpg(capturas_dir.path_join(nombre + ".jpg"), 0.9)
	print("[PruebaAnime] ", nombre)


func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(capturas_dir)
	await get_tree().create_timer(0.6).timeout
	var lista: Array = []
	# 1) comparación v13 / anime en los encuadres principales a la hora de la demo (atardecer)
	for e in [Ajustes.ESTILO_PICTORICO, Ajustes.ESTILO_ANIME]:
		for p in ["general", "amarillo_cara", "negro_cara"]:
			lista.append([e, 16.5, -1, p, true])
	if plan == "contorno":
		lista = [[Ajustes.ESTILO_ANIME, 16.5, -1, "amarillo_cara", false], [Ajustes.ESTILO_ANIME, 16.5, -1, "general", false]]
		for h in [9.0, 13.0, 18.2, 21.0]:
			lista.append([Ajustes.ESTILO_ANIME, h, -1, "general", true])
	if plan == "follaje":
		lista = [[Ajustes.ESTILO_ANIME, 16.5, -1, "follaje", true], [Ajustes.ESTILO_ANIME, 16.5, -1, "arbol", true], [Ajustes.ESTILO_ANIME, 16.5, -1, "general", true]]
	if plan == "completo":
		for p in ["personajes", "esferas", "madera_roca", "follaje", "arbol"]:
			lista.append([Ajustes.ESTILO_ANIME, 16.5, -1, p, true])
		# 2) horas del ciclo
		for h in [9.0, 13.0, 18.2, 21.0]:
			lista.append([Ajustes.ESTILO_ANIME, h, -1, "general", true])
		# 3) ángulos de sol sobre esferas, personajes y madera/roca
		for i in SOLES.size():
			for p in ["esferas", "personajes"]:
				lista.append([Ajustes.ESTILO_ANIME, 13.0, i, p, true])
		# 4) sin contornos
		lista.append([Ajustes.ESTILO_ANIME, 16.5, -1, "general", false])
		lista.append([Ajustes.ESTILO_ANIME, 16.5, -1, "amarillo_cara", false])
	for c in lista:
		Ajustes.contornos = c[4]
		sol_idx = c[2]
		hora = c[1]
		aplicar_estilo(c[0])
		set_plano(c[3])
		var nombre := "%s_%s_h%s_%s%s" % ["anime" if c[0] == Ajustes.ESTILO_ANIME else "v13", c[3], str(c[1]).replace(".", "_"),
			"ciclo" if c[2] < 0 else String(SOLES[c[2]][0]), "" if c[4] else "_sin_contorno"]
		await _shot(nombre)
	Ajustes.contornos = true
	get_tree().quit()
