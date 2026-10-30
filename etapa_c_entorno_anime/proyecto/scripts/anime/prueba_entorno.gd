class_name PruebaEntorno
extends PruebaAnime
## Etapa C del estilo anime: entorno selvático de prueba. Hereda de la escena de la Etapa B (personajes,
## esferas, madera, follaje y capturas) y cambia, solo en el estilo anime: el suelo, la densidad de copas,
## las rocas, el cielo y la graduación de la luz. El estilo v13 no cambia y sirve para comparar.
##
## Captura automática (ocho tipos de imagen pedidos en la Etapa C):
##   godot --path . res://scenes/pruebas/PruebaEntornoAnime.tscn -- --capturas=/ruta

const ESCENA_ENTORNO := "res://scenes/pruebas/PruebaEntornoAnime.tscn"
const SEMILLA := 2026
const NOMBRES_ARBOL := ["ArbolSelva_0", "ArbolSelva_1", "ArbolSelva_2", "ArbolSelva_3", "ArbolSelva_4", "ArbolSelva_5", "ArbolSelva_6", "ArbolSelva_7"]
const NOMBRES_ROCA := ["V_boulder_01_0", "V_rock_moss_set_01_0", "V_root_cluster_01_0"]
## Color plano de cada roca escaneada en el estilo anime
const COLOR_ESCANEO := {"V_boulder_01_0": Color(0.47, 0.45, 0.41), "V_root_cluster_01_0": Color(0.38, 0.28, 0.2), "V_rock_moss_set_01_0": Color(0.45, 0.45, 0.4)}
## Árboles fijos, para tener encuadres repetibles: [nombre, posición, giro°, escala]
const ARBOLES_FIJOS := [["ArbolSelva_2", Vector3(-9.0, 0.0, -12.0), 0.0, 0.9], ["ArbolSelva_5", Vector3(11.0, 0.0, -11.0), 60.0, 0.85]]
## Encuadres de la Etapa C: [posición, mira, fov]
const PLANOS_C := {
	"copas": [Vector3(-4.5, 4.6, 3.0), Vector3(-9.0, 10.0, -12.0), 50.0],
	"vegetacion": [Vector3(3.4, 1.0, 3.2), Vector3(4.8, 0.7, -1.2), 50.0],
	"rocas": [Vector3(-3.2, 1.8, 2.6), Vector3(-7.0, 0.7, -5.0), 52.0],
	"terreno": [Vector3(0.0, 1.5, 6.0), Vector3(0.0, -0.6, -6.0), 60.0],
	"panoramica": [Vector3(0.0, 6.5, 15.0), Vector3(0.0, 3.0, -12.0), 62.0],
}
## Paleta del cielo por hora: [hora, color cenit, color horizonte]
const CIELO := [
	[9.0, Color(0.3, 0.58, 0.92), Color(0.66, 0.84, 0.92)],
	[13.0, Color(0.16, 0.48, 0.9), Color(0.46, 0.76, 0.95)],
	[16.5, Color(0.3, 0.52, 0.84), Color(0.98, 0.78, 0.52)],
	[18.2, Color(0.22, 0.22, 0.46), Color(0.98, 0.52, 0.36)],
	[21.0, Color(0.03, 0.04, 0.12), Color(0.12, 0.14, 0.28)],
]

var _sky_mat: ProceduralSkyMaterial


# ------------------------------------------------------------------ montaje
func _ready() -> void:
	super._ready()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--medir="):
			_medir.call_deferred(int(a.substr(8)))


func _entorno() -> void:
	super._entorno()
	# cielo propio del estilo anime; el del v13 sigue siendo el del ciclo día-noche
	_sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env_anime.sky = sky


func _suelo() -> void:
	var mi := _malla(EntornoSelva.malla_terreno(260.0, 128, SEMILLA), Vector3.ZERO)
	mi.name = "Suelo_Selva"
	_registrar(mi, 0, MaterialesMundo.get_material("Empedrado"), EntornoSelva.material_terreno())


func _madera_roca() -> void:
	super._madera_roca()
	# rocas escaneadas: menos ruido de textura, color más plano y volumen por bandas
	var lib := _biblioteca()
	for o in _objetos:
		var mi: MeshInstance3D = o[0]
		for n in NOMBRES_ROCA:
			var am := o[3] as ShaderMaterial
			if am and lib.get(n) == mi.mesh:
				# color plano propio (la foto del escaneo deja motas y un tono rosado con luz cálida)
				var c: Color = COLOR_ESCANEO.get(n, Color(0.46, 0.44, 0.4))
				am.set_shader_parameter("color_plano", Vector3(c.r, c.g, c.b))
				am.set_shader_parameter("detalle", 0.0)
				am.set_shader_parameter("variacion", 0.08)
				# raíces finas y aristas del escaneo: sin líneas interiores del contorno de pantalla
				# (solo la silueta), para que no se conviertan en ruido
				am.set_shader_parameter("mascara_contorno", EstiloAnime.MASCARA_FOLLAJE)
	# la roca grande y el conjunto con musgo son escaneos con microrrelieve: con sombreado por bandas
	# cada bulto se vuelve una mota de luz o sombra. En esta escena se sustituyen por rocas
	# estilizadas en el mismo sitio (la versión definitiva se remodela en Blender)
	for mi in get_children():
		if mi is MeshInstance3D and ((mi as MeshInstance3D).mesh == lib.get("V_rock_moss_set_01_0") or (mi as MeshInstance3D).mesh == lib.get("V_boulder_01_0")):
			(mi as MeshInstance3D).visible = false
	# rocas estilizadas nuevas: masas de piedra con relieve suave y musgo arriba. Van fuera de la sombra
	# de las copas: la sombra moteada de las hojas sobre una roca pequeña se lee como ruido
	var rocas := [[Vector3(-3.6, 0.0, -4.6), 0.85, Color(0.46, 0.45, 0.4)], [Vector3(-6.4, 0.0, -3.6), 1.45, Color(0.47, 0.45, 0.41)], [Vector3(-11.5, 0.0, -3.0), 1.5, Color(0.5, 0.46, 0.4)], [Vector3(-12.5, 0.0, -0.5), 0.9, Color(0.42, 0.44, 0.38)],
		[Vector3(6.0, 0.0, -4.5), 1.1, Color(0.55, 0.5, 0.42)], [Vector3(1.5, 0.0, -8.0), 0.7, Color(0.46, 0.42, 0.36)],
		[Vector3(9.0, 0.0, -6.0), 1.3, Color(0.5, 0.48, 0.44)]]
	for i in rocas.size():
		var r: Array = rocas[i]
		var mi := _malla(EntornoSelva.roca(SEMILLA + i, float(r[1])), r[0], Vector3(0, i * 37.0, 0))
		mi.name = "Roca_estilizada_%d" % i
		var v13 := StandardMaterial3D.new()
		v13.albedo_color = r[2]
		v13.roughness = 0.9
		v13.resource_name = "roca_selva"
		_registrar(mi, 0, v13, EstiloAnime.material_entorno({"nombre": "roca_estilizada", "color": r[2], "detalle": 0.1, "musgo": 0.4, "pintado": 3.0, "escala": 0.3}))


func _follaje() -> void:
	super._follaje()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA
	for a in ARBOLES_FIJOS:
		_plantar(a[0], a[1], a[2], a[3], true)
	# bosque de fondo: árboles repartidos a los lados y detrás, dejando libre el centro de la escena
	var colocados := 0
	var intentos := 0
	while colocados < 14 and intentos < 300:
		intentos += 1
		var ang := rng.randf() * TAU
		var r := rng.randf_range(11.0, 36.0)
		var p := Vector3(cos(ang) * r, 0.0, sin(ang) * r - 6.0)
		if absf(p.x) < 8.0 and p.z > -16.0:
			continue
		if p.distance_to(Vector3(-9.0, 0.0, -12.0)) < 6.0 or p.distance_to(Vector3(11.0, 0.0, -11.0)) < 6.0:
			continue
		_plantar(NOMBRES_ARBOL[rng.randi() % NOMBRES_ARBOL.size()], p, rng.randf_range(0.0, 360.0), rng.randf_range(0.7, 1.0), true)
		colocados += 1
	stats["arboles_extra"] = colocados


## Árbol de la biblioteca con sus materiales v13 y anime. Con 'copas' añade masas de copa volumétricas.
func _plantar(nombre: String, pos: Vector3, giro: float, s: float, copas: bool) -> MeshInstance3D:
	var mesh: Mesh = _biblioteca().get(nombre)
	if mesh == null:
		return null
	var mi := _malla(mesh, pos, Vector3(0, giro, 0), s)
	mi.name = nombre
	var centros: Array = EstiloAnime.centros_glb(LIB_GLB).get(nombre, [])
	for sf in mesh.get_surface_count():
		var orig := mesh.surface_get_material(sf)
		var n := String(orig.resource_name) if orig else ""
		var v13: Material
		if MaterialesMundo.PBR_TABLE.has(n) or n.begins_with("Hojas") or n in ["Hiedra", "Liana"]:
			v13 = MaterialesMundo.get_material(n, orig)
		else:
			v13 = MaterialesMundo.plant_material(n)
		_registrar(mi, sf, v13, _anime_para_vegetal(n, v13, centros, sf))
	if copas:
		_masas_de_copa(mi, nombre, pos.x * 7.0 + pos.z * 3.0)
	return mi


## Seis masas de copa irregulares alrededor de la copa del árbol (en coordenadas locales del árbol,
## así escalan y giran con él). Dan silueta y volumen, en lugar de hojas sueltas.
func _masas_de_copa(mi: MeshInstance3D, nombre: String, semilla: float) -> void:
	var centros: Array = EstiloAnime.centros_glb(LIB_GLB).get(nombre, [])
	var c := Vector3(0.5, 12.0, 0.7)
	if not centros.is_empty():
		c = Vector3.ZERO
		for k in centros:
			c += k
		c /= float(centros.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = int(semilla) + SEMILLA
	var tonos := [Color(0.17, 0.38, 0.15), Color(0.14, 0.32, 0.17), Color(0.23, 0.45, 0.17), Color(0.19, 0.4, 0.2), Color(0.26, 0.47, 0.15), Color(0.15, 0.35, 0.13)]
	for k in tonos.size():
		var blob := MeshInstance3D.new()
		blob.mesh = EntornoSelva.copa(rng.randi(), rng.randf_range(2.4, 3.8))
		blob.position = c + Vector3(rng.randf_range(-5.0, 5.0), rng.randf_range(-1.5, 2.5), rng.randf_range(-5.0, 5.0))
		blob.name = "Copa_%d" % k
		mi.add_child(blob)
		var an := EstiloAnime.material_entorno({"nombre": "copa", "color": tonos[k], "detalle": 0.12, "pintado": 2.0, "escala": 0.25, "umbral": 0.04})
		_registrar(blob, 0, MaterialesMundo.get_material("Hojas_Dosel"), an)


# ------------------------------------------------------------------ cielo y luz
func set_hora(h: float) -> void:
	super.set_hora(h)
	if estilo != Ajustes.ESTILO_ANIME:
		return
	var c := _paleta_cielo(h)
	_sky_mat.sky_top_color = c[0]
	_sky_mat.sky_horizon_color = c[1]
	# el horizonte del suelo es verde grisáceo (bruma de selva), no azul: si no, parece un mar.
	# De noche la bruma se oscurece con el cielo para que no brille.
	var bruma: Color = Color(0.5, 0.64, 0.56).lerp(c[1], 0.45) * clampf((c[1] as Color).v * 1.15, 0.22, 1.0)
	_sky_mat.ground_horizon_color = bruma
	_sky_mat.ground_bottom_color = Color(0.12, 0.24, 0.12)
	var e := we.environment
	# bruma de selva: el mismo color en la niebla y en el horizonte del suelo, para que el final del
	# terreno no se vea como una franja
	e.fog_light_color = bruma
	e.fog_density = 0.7
	e.fog_depth_begin = 25.0
	e.fog_depth_end = 125.0
	# colores vivos al mediodía: más saturación y contraste, sin subir la exposición (evita el blanco)
	e.adjustment_saturation = 1.16
	e.adjustment_contrast = 1.06


func _paleta_cielo(h: float) -> Array:
	if h <= CIELO[0][0]:
		return [CIELO[0][1], CIELO[0][2]]
	for i in range(CIELO.size() - 1):
		var a: Array = CIELO[i]
		var b: Array = CIELO[i + 1]
		if h <= float(b[0]):
			var t := (h - float(a[0])) / (float(b[0]) - float(a[0]))
			return [(a[1] as Color).lerp(b[1], t), (a[2] as Color).lerp(b[2], t)]
	var last: Array = CIELO[CIELO.size() - 1]
	return [last[1], last[2]]


func set_plano(n: String) -> void:
	if not PLANOS_C.has(n):
		super.set_plano(n)
		return
	plano = n
	var p: Array = PLANOS_C[n]
	cam.fov = float(p[2])
	cam.look_at_from_position(p[0], p[1], Vector3.UP)
	_refresh_info()


# ------------------------------------------------------------------ capturas
func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(capturas_dir)
	await get_tree().create_timer(0.6).timeout
	var A := Ajustes.ESTILO_ANIME
	var V := Ajustes.ESTILO_PICTORICO
	var lista := [
		[A, 16.5, "panoramica", "anime_entorno_general_h16_5"],
		[A, 16.5, "copas", "anime_copas_primer_plano"],
		[A, 16.5, "vegetacion", "anime_vegetacion_primer_plano"],
		[A, 16.5, "rocas", "anime_rocas_primer_plano"],
		[A, 16.5, "terreno", "anime_terreno"],
		[A, 13.0, "panoramica", "anime_iluminacion_mediodia_h13"],
		[A, 18.2, "panoramica", "anime_ciclo_atardecer_h18_2"],
		[A, 21.0, "panoramica", "anime_ciclo_noche_h21"],
		[V, 16.5, "panoramica", "v13_entorno_general_h16_5"],
		[V, 16.5, "copas", "v13_copas_primer_plano"],
		[V, 13.0, "panoramica", "v13_iluminacion_mediodia_h13"],
	]
	for c in lista:
		Ajustes.contornos = true
		sol_idx = -1
		hora = c[1]
		aplicar_estilo(c[0])
		set_plano(c[2])
		await _shot(c[3])
	Ajustes.contornos = true
	get_tree().quit()


# ------------------------------------------------------------------ rendimiento
## Mide el tiempo medio de fotograma en el encuadre panorámico con cada estilo (sin límite de FPS).
## Imprime una línea "[medida]" por estilo con fps medio, ms por fotograma, llamadas de dibujo y triángulos.
func _medir(fotogramas: int) -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for e in [Ajustes.ESTILO_PICTORICO, Ajustes.ESTILO_ANIME]:
		hora = 16.5
		aplicar_estilo(e)
		set_plano("panoramica")
		for i in 30:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		for i in fotogramas:
			await get_tree().process_frame
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(fotogramas)
		print("[medida] estilo=%s fotogramas=%d ms=%.2f fps=%.2f dibujos=%d triangulos=%d" % [
			"anime" if e == Ajustes.ESTILO_ANIME else "v13", fotogramas, ms, 1000.0 / ms,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	get_tree().quit()
