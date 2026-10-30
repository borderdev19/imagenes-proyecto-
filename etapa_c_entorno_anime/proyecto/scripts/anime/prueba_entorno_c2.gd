class_name PruebaEntornoC2
extends PruebaAnime
## Etapa C del estilo anime, revisión C2: claro de selva con un camino, montado solo para revisar el
## entorno. No hay esferas ni objetos de laboratorio; el Pollo Amarillo solo aparece en el plano de
## escala. Con Tab se compara con el v13: mismo sitio, misma cámara y misma hora, con los árboles,
## rocas y materiales originales del v13 en lugar de los nuevos.
##
## Teclas: Tab estilo · 1-7 encuadre · H hora · O contornos · Esc menú.
## Capturas: godot --path . res://scenes/pruebas/PruebaEntornoAnimeC2.tscn -- --capturas=/ruta
## Medición: ... -- --medir=120

const ESCENA_C2 := "res://scenes/pruebas/PruebaEntornoAnimeC2.tscn"
const SEMILLA_C2 := 4242
const SUELO_LADO := 640.0
const HORAS_C2 := [6.5, 9.0, 13.0, 16.5, 18.2, 19.5, 21.0, 0.0]

## Luz anime por hora: [hora, cenit, horizonte, bruma, color sol, energía sol, elevación°, azimut°
## (0 = norte, 90 = este), energía ambiente, color ambiente]
const LUZ := [
	[0.0, Color(0.02, 0.035, 0.1), Color(0.08, 0.11, 0.2), Color(0.06, 0.085, 0.13), Color(0.55, 0.66, 0.95), 0.5, 42.0, 150.0, 0.55, Color(0.42, 0.52, 0.8)],
	[5.5, Color(0.05, 0.07, 0.18), Color(0.22, 0.21, 0.3), Color(0.13, 0.14, 0.18), Color(0.6, 0.66, 0.92), 0.3, 30.0, 140.0, 0.4, Color(0.42, 0.5, 0.72)],
	[6.5, Color(0.2, 0.32, 0.58), Color(0.8, 0.64, 0.52), Color(0.4, 0.42, 0.42), Color(1.0, 0.78, 0.6), 0.8, 6.0, 85.0, 0.4, Color(0.6, 0.62, 0.7)],
	[9.0, Color(0.2, 0.42, 0.76), Color(0.56, 0.7, 0.78), Color(0.42, 0.52, 0.48), Color(1.0, 0.93, 0.82), 1.15, 34.0, 100.0, 0.34, Color(0.62, 0.68, 0.78)],
	[13.0, Color(0.17, 0.4, 0.74), Color(0.5, 0.66, 0.76), Color(0.42, 0.52, 0.47), Color(1.0, 0.97, 0.9), 1.3, 58.0, 118.0, 0.3, Color(0.6, 0.67, 0.78)],
	[16.5, Color(0.2, 0.4, 0.72), Color(0.66, 0.68, 0.64), Color(0.43, 0.5, 0.45), Color(1.0, 0.9, 0.78), 1.15, 28.0, 245.0, 0.32, Color(0.62, 0.66, 0.74)],
	[18.2, Color(0.18, 0.22, 0.45), Color(0.8, 0.56, 0.45), Color(0.36, 0.35, 0.37), Color(1.0, 0.76, 0.58), 0.95, 8.0, 270.0, 0.36, Color(0.58, 0.58, 0.68)],
	[19.5, Color(0.07, 0.09, 0.22), Color(0.24, 0.22, 0.32), Color(0.14, 0.15, 0.2), Color(0.58, 0.64, 0.92), 0.45, 25.0, 140.0, 0.5, Color(0.44, 0.5, 0.74)],
	[24.0, Color(0.02, 0.035, 0.1), Color(0.08, 0.11, 0.2), Color(0.06, 0.085, 0.13), Color(0.55, 0.66, 0.95), 0.5, 42.0, 150.0, 0.55, Color(0.42, 0.52, 0.8)],
]

var _sky_c2: ProceduralSkyMaterial
var _solo_anime: Array[Node3D] = []
var _solo_v13: Array[Node3D] = []
var _multis: Array = []          # [MultiMeshInstance3D, material v13, material anime]
var _huellas: Array = []         # Vector4(x, z, radio de copa, 0) de los árboles cercanos (para el suelo)
var _planos_c2 := {}
var _rocas_pos: Array = []      # [Vector2, radio]: el sotobosque no crece encima de las rocas
var _ocupado: Array = []         # [Vector2 posición, radio] de troncos y rocas, para no solaparlos
var especies := {"ceiba": 0, "redonda": 0, "joven": 0, "palma": 0, "lejano": 0}
var _medir_n := 0
var _solo: PackedStringArray = []   # --solo=general,rocas: solo esos planos (iteración rápida)
var _solo_estilo := -1


func _ready() -> void:
	estilo = Ajustes.ESTILO_ANIME
	hora = 13.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			capturas_dir = a.substr(11)
		elif a.begins_with("--estilo="):
			estilo = Ajustes.ESTILO_PICTORICO if a.substr(9) == "v13" else Ajustes.ESTILO_ANIME
		elif a.begins_with("--solo="):
			_solo = a.substr(7).split(",")
		elif a.begins_with("--solo_estilo="):
			_solo_estilo = Ajustes.ESTILO_PICTORICO if a.substr(14) == "v13" else Ajustes.ESTILO_ANIME
		elif a.begins_with("--medir="):
			_medir_n = int(a.substr(8))
	_entorno()
	_cielo_c2()
	_camara()
	cam.far = 900.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	_bosque()
	_suelo_c2()
	_rocas_c2()
	_sotobosque()
	_tronco_caido()
	_heroe()
	_ui()
	_planos_c2 = _calcular_planos()
	aplicar_estilo(estilo)
	set_plano("general")
	if capturas_dir != "":
		_capturar.call_deferred()
	elif _medir_n > 0:
		_medir.call_deferred(_medir_n)


# ------------------------------------------------------------------ cielo
func _cielo_c2() -> void:
	_sky_c2 = ProceduralSkyMaterial.new()
	_sky_c2.sky_curve = 0.12
	_sky_c2.ground_curve = 0.02
	_sky_c2.sun_angle_max = 18.0
	_sky_c2.use_debanding = true
	var sky := Sky.new()
	sky.sky_material = _sky_c2
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env_anime.sky = sky
	# perfil anime C2: menos ambiente plano y más contraste del sol, saturación contenida
	env_anime.tonemap_exposure = 1.0
	env_anime.tonemap_white = 6.0
	env_anime.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_anime.ssao_enabled = EstiloAnime.forward_plus()
	env_anime.ssao_radius = 1.4
	env_anime.ssao_intensity = 1.4
	env_anime.adjustment_saturation = 1.06
	env_anime.adjustment_contrast = 1.1
	env_anime.adjustment_brightness = 1.0
	env_anime.glow_intensity = 0.22
	env_anime.fog_mode = Environment.FOG_MODE_DEPTH
	env_anime.fog_depth_begin = 22.0
	env_anime.fog_depth_end = 160.0
	env_anime.fog_depth_curve = 1.2
	env_anime.fog_density = 0.9
	env_anime.fog_aerial_perspective = 0.15
	env_anime.fog_sky_affect = 0.0
	env_v13.fog_depth_end = 160.0


## Valores de la tabla LUZ interpolados para la hora h.
func luz_para(h: float) -> Array:
	h = fposmod(h, 24.0)
	for i in LUZ.size() - 1:
		var a: Array = LUZ[i]
		var b: Array = LUZ[i + 1]
		if h >= float(a[0]) and h <= float(b[0]):
			var t := (h - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			t = t * t * (3.0 - 2.0 * t)
			var out := [h]
			for k in range(1, a.size()):
				if a[k] is Color:
					out.append((a[k] as Color).lerp(b[k], t))
				elif k == 7:
					out.append(float(a[k]) + wrapf(float(b[k]) - float(a[k]), -180.0, 180.0) * t)
				else:
					out.append(lerpf(float(a[k]), float(b[k]), t))
			return out
	return LUZ[0]


func _luz_anime(h: float) -> void:
	var p := luz_para(h)
	var bruma: Color = p[3]
	_sky_c2.sky_top_color = p[1]
	# el horizonte del cielo se acerca a la bruma: sin franja azul entre el bosque lejano y el cielo
	_sky_c2.sky_horizon_color = (p[2] as Color).lerp(bruma, 0.35)
	_sky_c2.ground_horizon_color = bruma
	_sky_c2.ground_bottom_color = bruma * 0.6
	_sky_c2.sun_curve = 0.15
	var e := env_anime
	e.fog_light_color = bruma
	e.ambient_light_color = p[9]
	e.ambient_light_energy = float(p[8])
	var elev := deg_to_rad(float(p[6]))
	var az := deg_to_rad(float(p[7]))
	var to_sun := Vector3(sin(az) * cos(elev), sin(elev), -cos(az) * cos(elev)).normalized()
	sun.look_at_from_position(Vector3.ZERO, -to_sun, Vector3.UP if absf(to_sun.y) < 0.99 else Vector3.FORWARD)
	sun.light_color = p[4]
	sun.light_energy = float(p[5])


func set_hora(h: float) -> void:
	hora = h
	ciclo.set_hour(h)
	if estilo == Ajustes.ESTILO_ANIME:
		_luz_anime(h)
	_refresh_info()


# ------------------------------------------------------------------ bosque
func _libre(p: Vector3, r: float) -> bool:
	for o in _ocupado:
		if Vector2(p.x, p.z).distance_to(o[0]) < r + float(o[1]):
			return false
	return true


func _ocupar(p: Vector3, r: float) -> void:
	_ocupado.append([Vector2(p.x, p.z), r])


func _bosque() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C2
	# variantes por especie (cada una distinta; se giran y escalan al colocarlas)
	var variantes := {SelvaC2.Especie.CEIBA: [], SelvaC2.Especie.REDONDA: [], SelvaC2.Especie.JOVEN: []}
	for esp in variantes:
		var n := 5 if esp == SelvaC2.Especie.CEIBA else (8 if esp == SelvaC2.Especie.REDONDA else 6)
		for k in n:
			(variantes[esp] as Array).append(SelvaC2.arbol(esp, SEMILLA_C2 + esp * 100 + k))
	var corteza := {
		SelvaC2.Especie.CEIBA: EstiloAnime.material_entorno({"nombre": "corteza_ceiba", "tex": _tex("corteza_col.jpg"), "color": Color(0.5, 0.46, 0.42).srgb_to_linear(), "escala": 0.45, "detalle": 0.35, "pintado": 2.5, "musgo": 0.15, "bandas": 3}),
		SelvaC2.Especie.REDONDA: EstiloAnime.material_entorno({"nombre": "corteza_redonda", "tex": _tex("corteza_col.jpg"), "color": Color(0.38, 0.27, 0.2).srgb_to_linear(), "escala": 0.5, "detalle": 0.35, "pintado": 2.5, "musgo": 0.2, "bandas": 3}),
		SelvaC2.Especie.JOVEN: EstiloAnime.material_entorno({"nombre": "corteza_joven", "tex": _tex("corteza_col.jpg"), "color": Color(0.4, 0.32, 0.23).srgb_to_linear(), "escala": 0.6, "detalle": 0.3, "pintado": 2.5, "bandas": 3}),
	}
	# tonos de copa por especie (hoja en sombra, hoja iluminada)
	var copas := {
		SelvaC2.Especie.CEIBA: [SelvaC2.material_copa(Color(0.09, 0.24, 0.12), Color(0.28, 0.46, 0.17)), SelvaC2.material_copa(Color(0.1, 0.25, 0.1), Color(0.33, 0.48, 0.15))],
		SelvaC2.Especie.REDONDA: [SelvaC2.material_copa(Color(0.11, 0.28, 0.09), Color(0.36, 0.54, 0.16)), SelvaC2.material_copa(Color(0.15, 0.29, 0.08), Color(0.44, 0.55, 0.15)),
			SelvaC2.material_copa(Color(0.09, 0.26, 0.12), Color(0.3, 0.5, 0.2))],
		SelvaC2.Especie.JOVEN: [SelvaC2.material_copa(Color(0.09, 0.26, 0.13), Color(0.27, 0.47, 0.21)), SelvaC2.material_copa(Color(0.11, 0.28, 0.11), Color(0.32, 0.5, 0.17))],
	}
	# árboles protagonistas, en sitios fijos para que los encuadres se repitan
	var fijos := [[SelvaC2.Especie.CEIBA, Vector3(-11.0, 0, -20.0), 1.0], [SelvaC2.Especie.CEIBA, Vector3(15.0, 0, -40.0), 1.1],
		[SelvaC2.Especie.REDONDA, Vector3(7.5, 0, -7.0), 1.15], [SelvaC2.Especie.REDONDA, Vector3(-7.0, 0, -9.5), 1.0],
		[SelvaC2.Especie.JOVEN, Vector3(-5.5, 0, 6.0), 1.0], [SelvaC2.Especie.REDONDA, Vector3(-8.5, 0, -31.0), 1.2],
		[SelvaC2.Especie.JOVEN, Vector3(8.0, 0, -18.0), 1.1]]
	for f in fijos:
		_colocar_arbol(f[0], f[1], rng.randf() * 360.0, f[2], variantes, corteza, copas, rng, false)
	# bosque cercano: especies según la distancia al camino; el camino y el primer plano quedan libres
	var colocados := 0
	var intentos := 0
	while colocados < 130 and intentos < 6000:
		intentos += 1
		var p := Vector3(rng.randf_range(-55.0, 55.0), 0, rng.randf_range(-105.0, 24.0))
		var dc := SelvaC2.distancia_camino(p)
		if dc < 4.2:
			continue
		if p.z > 6.0 and dc < 9.0:
			continue
		var cerca := dc < 12.0
		var u := rng.randf()
		var esp: int
		if cerca:
			esp = SelvaC2.Especie.REDONDA if u < 0.42 else (SelvaC2.Especie.JOVEN if u < 0.72 else (-1 if u < 0.9 else SelvaC2.Especie.CEIBA))
		else:
			esp = SelvaC2.Especie.REDONDA if u < 0.48 else (SelvaC2.Especie.CEIBA if u < 0.72 else (SelvaC2.Especie.JOVEN if u < 0.88 else -1))
		var radio: float = {SelvaC2.Especie.CEIBA: 7.0, SelvaC2.Especie.REDONDA: 4.2, SelvaC2.Especie.JOVEN: 2.6, -1: 3.2}[esp]
		if not _libre(p, radio):
			continue
		if esp == -1:
			_palma(p, rng)
		else:
			_colocar_arbol(esp, p, rng.randf() * 360.0, rng.randf_range(0.85, 1.2), variantes, corteza, copas, rng, false)
		colocados += 1
	# anillo lejano: silueta del bosque que continúa hasta la bruma (sin hueco en el horizonte)
	var lejanos := 0
	intentos = 0
	while lejanos < 190 and intentos < 5000:
		intentos += 1
		var ang := rng.randf_range(-PI, PI)
		var r := rng.randf_range(58.0, 200.0)
		var p := Vector3(sin(ang) * r, 0, -cos(ang) * r - 25.0)
		if not _libre(p, 4.5):
			continue
		var esp: int = SelvaC2.Especie.CEIBA if rng.randf() < 0.3 else SelvaC2.Especie.REDONDA
		_colocar_arbol(esp, p, rng.randf() * 360.0, rng.randf_range(1.3, 2.0), variantes, corteza, copas, rng, true)
		lejanos += 1
	especies["lejano"] = lejanos
	var muro := _malla(SelvaC2.muro_lejano(SEMILLA_C2 + 3, Vector3(0, 0, -25.0), 175.0, 235.0, 150), Vector3.ZERO)
	muro.name = "Selva_lejana"
	muro.set_surface_override_material(0, (copas[SelvaC2.Especie.REDONDA] as Array)[0])
	muro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solo_anime.append(muro)


func _colocar_arbol(esp: int, p: Vector3, giro: float, s: float, variantes: Dictionary, corteza: Dictionary, copas: Dictionary, rng: RandomNumberGenerator, lejano: bool) -> void:
	var lista: Array = variantes[esp]
	var info: Dictionary = lista[rng.randi() % lista.size()]
	p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - 0.1
	var mi := _malla(info["mesh"], p, Vector3(0, giro, 0), s)
	mi.name = "Arbol_%s" % ["ceiba", "redonda", "joven"][esp]
	var tintes: Array = copas[esp]
	mi.set_surface_override_material(0, corteza[esp])
	mi.set_surface_override_material(1, tintes[rng.randi() % tintes.size()])
	_solo_anime.append(mi)
	var rc: float = float(info["radio_copa"]) * s
	_ocupar(p, {SelvaC2.Especie.CEIBA: 6.0, SelvaC2.Especie.REDONDA: 3.6, SelvaC2.Especie.JOVEN: 2.2}[esp] * s)
	if not lejano:
		especies[["ceiba", "redonda", "joven"][esp]] += 1
		_huellas.append(Vector4(p.x, p.z, maxf(rc, 2.0), 0.0))
	# equivalente v13 en el mismo sitio (árbol de la biblioteca con sus materiales originales)
	var v13_nombre: String = {SelvaC2.Especie.CEIBA: ["ArbolSelva_5", "ArbolSelva_7"], SelvaC2.Especie.REDONDA: ["ArbolSelva_0", "ArbolSelva_1", "ArbolSelva_2"],
		SelvaC2.Especie.JOVEN: ["ArbolSelva_3", "ArbolSelva_4"]}[esp][rng.randi() % (2 if esp != SelvaC2.Especie.REDONDA else 3)]
	var v13_escala: float = {SelvaC2.Especie.CEIBA: 0.75, SelvaC2.Especie.REDONDA: 0.62, SelvaC2.Especie.JOVEN: 0.32}[esp] * s
	var v := _planta_v13(v13_nombre, p, giro, v13_escala)
	if v:
		_solo_v13.append(v)


## Planta de la biblioteca solo con sus materiales v13.
func _planta_v13(nombre: String, p: Vector3, giro: float, s: float) -> MeshInstance3D:
	var mesh: Mesh = _biblioteca().get(nombre)
	if mesh == null:
		return null
	var mi := _malla(mesh, p, Vector3(0, giro, 0), s)
	mi.name = "v13_" + nombre
	for sf in mesh.get_surface_count():
		mi.set_surface_override_material(sf, _v13_de(mesh.surface_get_material(sf)))
	return mi


func _v13_de(orig: Material) -> Material:
	var n := String(orig.resource_name) if orig else ""
	if MaterialesMundo.PBR_TABLE.has(n) or n.begins_with("Hojas") or n in ["Hiedra", "Liana"]:
		return MaterialesMundo.get_material(n, orig)
	return MaterialesMundo.plant_material(n)


## Planta de la biblioteca con material v13 y anime (visible en los dos estilos).
func _planta(nombre: String, p: Vector3, giro: float, s: float) -> MeshInstance3D:
	var mesh: Mesh = _biblioteca().get(nombre)
	if mesh == null:
		return null
	p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - 0.03
	var mi := _malla(mesh, p, Vector3(0, giro, 0), s)
	mi.name = nombre
	var centros: Array = EstiloAnime.centros_glb(LIB_GLB).get(nombre, [])
	for sf in mesh.get_surface_count():
		var v13 := _v13_de(mesh.surface_get_material(sf))
		var n := String(mesh.surface_get_material(sf).resource_name) if mesh.surface_get_material(sf) else ""
		_registrar(mi, sf, v13, _veg_c2(_anime_para_vegetal(n, v13, centros, sf)))
	return mi


## Verde del sotobosque más profundo que en el laboratorio de la Etapa B: a pleno sol las hojas grandes
## se iban a verde menta.
func _veg_c2(m: Material) -> Material:
	var sm := m as ShaderMaterial
	if sm and sm.shader == EstiloAnime.SH_FOLLAJE:
		var c: Vector3 = sm.get_shader_parameter("color_hoja")
		var t: Vector3 = sm.get_shader_parameter("color_punta")
		sm.set_shader_parameter("color_hoja", c * Vector3(0.6, 0.66, 0.52))
		sm.set_shader_parameter("color_punta", t * Vector3(0.64, 0.72, 0.54))
		sm.set_shader_parameter("translucidez", 0.12)
	return sm if sm else m


func _palma(p: Vector3, rng: RandomNumberGenerator) -> void:
	_planta("Palma_%d" % rng.randi_range(0, 2), p, rng.randf() * 360.0, rng.randf_range(0.5, 0.7))
	_ocupar(p, 2.0)
	especies["palma"] += 1


# ------------------------------------------------------------------ suelo
func _suelo_c2() -> void:
	var mi := _malla(SelvaC2.malla_suelo(SUELO_LADO, 220, SEMILLA_C2), Vector3.ZERO)
	mi.name = "Suelo_Selva_C2"
	# las huellas más cercanas al centro de la escena primero (el shader admite 64)
	_huellas.sort_custom(func(a: Vector4, b: Vector4) -> bool: return Vector2(a.x, a.y + 15.0).length() < Vector2(b.x, b.y + 15.0).length())
	_registrar(mi, 0, MaterialesMundo.get_material("Terreno"), SelvaC2.material_suelo(_huellas))


# ------------------------------------------------------------------ rocas
func _rocas_c2() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C2 + 7
	# tonos de piedra en sRGB (el material los recibe en lineal)
	var tonos := [Color(0.4, 0.39, 0.36), Color(0.36, 0.37, 0.35), Color(0.43, 0.4, 0.35), Color(0.38, 0.36, 0.32)]
	# grupos: [centro, [[semiejes], ...], musgo]
	var zc := -12.0
	var grupos := [
		[Vector3(SelvaC2.camino_x(zc) - 4.0, 0, zc), [Vector3(1.6, 1.1, 1.3), Vector3(0.9, 0.7, 0.8), Vector3(0.5, 0.32, 0.45), Vector3(0.3, 0.2, 0.28), Vector3(0.22, 0.16, 0.2)], true],
		[Vector3(SelvaC2.camino_x(-27.0) + 4.4, 0, -27.0), [Vector3(1.2, 0.9, 1.0), Vector3(0.7, 0.5, 0.6), Vector3(0.35, 0.25, 0.3)], false],
		[Vector3(-12.5, 0, -16.0), [Vector3(1.0, 0.8, 0.9), Vector3(0.6, 0.4, 0.5)], true],
		[Vector3(SelvaC2.camino_x(3.0) + 3.6, 0, 3.0), [Vector3(0.7, 0.45, 0.6), Vector3(0.35, 0.22, 0.3)], false],
		[Vector3(SelvaC2.camino_x(-45.0) - 4.5, 0, -45.0), [Vector3(1.4, 1.0, 1.1), Vector3(0.8, 0.55, 0.7)], true],
	]
	var n := 0
	for g in grupos:
		var c: Vector3 = g[0]
		var rocas: Array = g[1]
		for i in rocas.size():
			var tam: Vector3 = rocas[i] * rng.randf_range(0.9, 1.15)
			var off := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * ((rocas[0] as Vector3).x + tam.x) * rng.randf_range(0.6, 0.95)
			var p := c + off
			if SelvaC2.distancia_camino(p) < 1.8:
				p.x += signf(p.x - SelvaC2.camino_x(p.z)) * 1.2
			_roca(p, tam, rng, tonos[rng.randi() % tonos.size()], bool(g[2]) and i < 2, n)
			n += 1
	# piedras sueltas repartidas fuera del camino
	var sueltas := 0
	while sueltas < 14:
		var p := Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-70, 15))
		if SelvaC2.distancia_camino(p) < 3.0 or not _libre(p, 1.0):
			continue
		var t := rng.randf_range(0.25, 0.8)
		_roca(p, Vector3(t, t * rng.randf_range(0.5, 0.75), t * rng.randf_range(0.7, 1.0)), rng, tonos[rng.randi() % tonos.size()], false, n)
		n += 1
		sueltas += 1
	stats["rocas_c2"] = n


func _roca(p: Vector3, tam: Vector3, rng: RandomNumberGenerator, tono: Color, musgo: bool, i: int) -> void:
	p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2)
	var mi := _malla(SelvaC2.roca(SEMILLA_C2 + 31 * i, tam, rng.randi_range(7, 10)), p, Vector3(rng.randf_range(-5, 5), rng.randf() * 360.0, rng.randf_range(-5, 5)))
	mi.name = "Roca_C2_%d" % i
	var an := EstiloAnime.material_entorno({"nombre": "roca_c2", "tex": _tex("basalto_col.jpg" if i % 2 == 0 else "caliza_col.jpg"), "color": tono.srgb_to_linear(), "escala": 0.35,
		"detalle": 0.28, "pintado": 3.0, "musgo": 0.24 if musgo else 0.0, "bandas": 3})
	an.set_shader_parameter("musgo_color", Vector3(0.06, 0.12, 0.03))
	mi.set_surface_override_material(0, an)
	_solo_anime.append(mi)
	_ocupar(p, maxf(tam.x, tam.z))
	_rocas_pos.append([Vector2(p.x, p.z), maxf(tam.x, tam.z) + 0.6])
	# equivalente v13: roca escaneada de la biblioteca del mismo tamaño aproximado
	var nombre := "V_boulder_01_0" if tam.x > 0.8 else ("V_rock_moss_set_02_%d" % (i % 3))
	var base := 1.0 if nombre == "V_boulder_01_0" else 0.6
	var v := _planta_v13(nombre, p, rng.randf() * 360.0, tam.y * 2.0 / base)
	if v:
		_solo_v13.append(v)


# ------------------------------------------------------------------ sotobosque
func _sotobosque() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C2 + 13
	# plantas grandes al pie de los árboles cercanos y en las orillas del camino
	var grandes := ["Monstera_0", "Monstera_1", "Monstera_2", "Helecho_Arbol_0", "Helecho_Arbol_1", "Platanera_0", "Platanera_1", "V_shrub_02_0", "V_shrub_02_1"]
	var escala := {"Monstera_0": 1.3, "Monstera_1": 1.3, "Monstera_2": 1.5, "Helecho_Arbol_0": 0.7, "Helecho_Arbol_1": 0.6, "Platanera_0": 0.9, "Platanera_1": 0.85,
		"V_shrub_02_0": 1.1, "V_shrub_02_1": 1.1}
	var n := 0
	for h in _huellas:
		if Vector2(h.x, h.y + 20.0).length() > 45.0:
			continue
		for k in rng.randi_range(1, 3):
			var a := rng.randf() * TAU
			var p := Vector3(h.x + cos(a) * rng.randf_range(1.2, 3.0), 0, h.y + sin(a) * rng.randf_range(1.2, 3.0))
			if SelvaC2.distancia_camino(p) < 2.2 or _sobre_roca(p):
				continue
			var nom: String = grandes[rng.randi() % grandes.size()]
			_planta(nom, p, rng.randf() * 360.0, escala[nom] * rng.randf_range(0.85, 1.2))
			n += 1
	# primer plano de vegetación: grupo junto al camino para el encuadre de vegetación
	var zv := 1.5
	for e in [["Monstera_0", 3.0, 0.0, 1.5], ["Helecho_Arbol_1", 4.6, -1.6, 0.7], ["V_shrub_02_0", 4.0, 1.4, 1.0], ["Monstera_2", 2.6, -2.2, 1.6], ["Platanera_1", 5.6, -0.4, 0.95]]:
		_planta(e[0], Vector3(SelvaC2.camino_x(zv + e[2]) + e[1], 0, zv + e[2]), rng.randf() * 360.0, e[3])
		n += 1
	stats["plantas_grandes"] = n
	# plantas pequeñas en grupos (MultiMesh): helecho, hierba, calathea y anthurium
	var pequenas := [["V_fern_02_1", 2.3, 600, 1.6, 6.0], ["V_fern_02_0", 2.6, 300, 2.0, 8.0], ["V_grass_medium_02_1", 3.6, 700, 1.5, 9.0], ["V_grass_medium_02_2", 3.4, 500, 1.4, 12.0],
		["V_calathea_orbifolia_01_0", 2.0, 120, 2.0, 6.0], ["V_anthurium_botany_01_0", 1.8, 90, 2.0, 7.0], ["V_shrub_02_0", 1.0, 90, 2.4, 10.0]]
	for e in pequenas:
		_grupo_pequeno(e[0], e[1], e[2], e[3], e[4], rng)


## 'n' plantas pequeñas agrupadas en manchas: la mitad en las orillas del camino (entre 'orilla' y
## 'lejos' metros del eje) y el resto al pie de los árboles cercanos.
func _grupo_pequeno(nombre: String, s: float, n: int, orilla: float, lejos: float, rng: RandomNumberGenerator) -> void:
	var mesh: Mesh = _biblioteca().get(nombre)
	if mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var ts: Array[Transform3D] = []
	var manchas := []
	for k in n / 8:
		var p: Vector3
		var u := rng.randf()
		if u < 0.3:
			# manchas sueltas en los claros, para que el suelo no sea un césped
			p = Vector3(rng.randf_range(-38.0, 38.0), 0, rng.randf_range(-75.0, 16.0))
			if SelvaC2.distancia_camino(p) < orilla + 1.0:
				continue
		elif u < 0.65:
			var z := rng.randf_range(-60.0, 12.0)
			var lado := -1.0 if rng.randf() < 0.5 else 1.0
			p = Vector3(SelvaC2.camino_x(z) + lado * rng.randf_range(orilla, lejos), 0, z)
		elif not _huellas.is_empty():
			var h: Vector4 = _huellas[rng.randi() % mini(_huellas.size(), 40)]
			var a := rng.randf() * TAU
			p = Vector3(h.x + cos(a) * rng.randf_range(1.0, h.z), 0, h.y + sin(a) * rng.randf_range(1.0, h.z))
		else:
			continue
		manchas.append(p)
	for k in n:
		if manchas.is_empty():
			break
		var c: Vector3 = manchas[k % manchas.size()]
		var p := c + Vector3(rng.randf_range(-1.4, 1.4), 0, rng.randf_range(-1.4, 1.4))
		if SelvaC2.distancia_camino(p) < orilla or _sobre_roca(p):
			continue
		p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - 0.02
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s * rng.randf_range(0.75, 1.25))
		ts.append(Transform3D(b, p))
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "Grupo_" + nombre
	add_child(mmi)
	var orig := mesh.surface_get_material(0)
	var v13 := _v13_de(orig)
	var an := _veg_c2(_anime_para_vegetal(String(orig.resource_name) if orig else "", v13, EstiloAnime.centros_glb(LIB_GLB).get(nombre, []), 0))
	_multis.append([mmi, v13, an])
	stats["pequenas_" + nombre] = ts.size()


func _sobre_roca(p: Vector3) -> bool:
	for r in _rocas_pos:
		if Vector2(p.x, p.z).distance_to(r[0]) < float(r[1]):
			return true
	return false


func _tronco_caido() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C2 + 21
	var z := -3.5
	var x := SelvaC2.camino_x(z) - 4.2
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := SelvaC2.altura_suelo(x, z, SEMILLA_C2)
	SelvaC2._tubo(st, [Vector3(x - 0.5, y + 0.28, z + 2.6), Vector3(x, y + 0.34, z), Vector3(x + 0.6, y + 0.3, z - 2.8)], [0.36, 0.34, 0.3], 12, rng, 0.05)
	var mi := _malla(st.commit(), Vector3.ZERO)
	mi.name = "Tronco_caido"
	var an := EstiloAnime.material_entorno({"nombre": "tronco_caido", "tex": _tex("corteza_col.jpg"), "color": Color(0.36, 0.27, 0.2).srgb_to_linear(), "escala": 0.5, "detalle": 0.35,
		"pintado": 2.5, "musgo": 0.22, "bandas": 3})
	an.set_shader_parameter("musgo_color", Vector3(0.06, 0.12, 0.03))
	_registrar(mi, 0, MaterialesMundo.get_material("Corteza"), an)
	_ocupar(Vector3(x, 0, z), 1.0)


func _heroe() -> void:
	amarillo = (load("res://scenes/characters/PolloAmarillo.tscn") as PackedScene).instantiate()
	add_child(amarillo)
	var z := 4.0
	amarillo.position = Vector3(SelvaC2.camino_x(z), SelvaC2.altura_suelo(SelvaC2.camino_x(z), z, SEMILLA_C2), z)
	amarillo.rotation_degrees = Vector3(0, 180, 0)
	amarillo.add_child(CombatStage.make_blob_shadow(0.45))
	amarillo.play.call_deferred("idle", 0.0)
	amarillo.visible = false


# ------------------------------------------------------------------ estado
func aplicar_estilo(e: int) -> void:
	estilo = e
	var anime := e == Ajustes.ESTILO_ANIME
	for o in _objetos:
		(o[0] as MeshInstance3D).set_surface_override_material(int(o[1]), o[3] if anime else o[2])
	for m in _multis:
		(m[0] as MultiMeshInstance3D).material_override = m[2] if anime else m[1]
	for n in _solo_anime:
		n.visible = anime
	for n in _solo_v13:
		n.visible = not anime
	if amarillo:
		if anime:
			EstiloAnime.aplicar_a_personaje(amarillo)
			EstiloAnime.contorno_personaje(amarillo, Ajustes.contornos)
		else:
			EstiloAnime.restaurar_personaje(amarillo)
	if anime:
		EstiloAnime.configurar_sol(sun)
	else:
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
	look.visible = not anime
	set_hora(hora)


func _calcular_planos() -> Dictionary:
	return {
		"general": [Vector3(SelvaC2.camino_x(17.0) + 1.0, 2.3, 17.0), Vector3(SelvaC2.camino_x(-24.0), 3.4, -24.0), 58.0],
		"profundidad": [Vector3(SelvaC2.camino_x(26.0), 11.0, 26.0), Vector3(SelvaC2.camino_x(-30.0), 1.5, -30.0), 60.0],
		"copas": [Vector3(0.0, 1.7, -3.0), Vector3(-7.0, 8.5, -24.0), 60.0],
		"vegetacion": [Vector3(SelvaC2.camino_x(6.5) + 1.2, 1.0, 6.5), Vector3(SelvaC2.camino_x(0.5) + 3.4, 0.9, 0.5), 52.0],
		"rocas": [Vector3(SelvaC2.camino_x(-8.0) + 0.3, 2.3, -8.0), Vector3(SelvaC2.camino_x(-12.0) - 4.0, 0.4, -12.3), 50.0],
		"terreno": [Vector3(SelvaC2.camino_x(4.0) + 1.0, 6.5, 4.0), Vector3(SelvaC2.camino_x(-12.0) - 1.0, 0.0, -12.0), 56.0],
		"escala": [Vector3(SelvaC2.camino_x(9.5) + 0.9, 2.5, 9.5), Vector3(SelvaC2.camino_x(-6.0), 1.4, -6.0), 54.0],
	}


func set_plano(n: String) -> void:
	if not _planos_c2.has(n):
		return
	plano = n
	var p: Array = _planos_c2[n]
	cam.fov = float(p[2])
	var pos: Vector3 = p[0]
	pos.y += SelvaC2.altura_suelo(pos.x, pos.z, SEMILLA_C2)
	cam.look_at_from_position(pos, p[1], Vector3.UP)
	if amarillo:
		amarillo.visible = n == "escala"
	_refresh_info()


func _refresh_info() -> void:
	if _info == null:
		return
	_info.text = "ENTORNO ANIME C2 · estilo: %s · hora %.1f · plano: %s · contornos: %s\nTab estilo · 1-7 plano · H hora · O contornos · Esc menú" % [
		Ajustes.ESTILOS[estilo], hora, plano, "sí" if Ajustes.contornos else "no"]


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := (ev as InputEventKey).keycode
	match k:
		KEY_TAB:
			aplicar_estilo(1 - estilo)
		KEY_H:
			var i := HORAS_C2.find(hora)
			set_hora(HORAS_C2[(i + 1) % HORAS_C2.size()])
		KEY_O:
			Ajustes.set_valor("contornos", 0 if Ajustes.contornos else 1)
			aplicar_estilo(estilo)
		KEY_ESCAPE:
			SceneRouter.change_scene(GameState.SCENE_MENU)
		_:
			if k >= KEY_1 and k <= KEY_7:
				set_plano(_planos_c2.keys()[k - KEY_1])


# ------------------------------------------------------------------ capturas y medición
func _shot(nombre: String) -> void:
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(capturas_dir.path_join(nombre + ".jpg"), 0.9)
	print("[PruebaEntornoC2] ", nombre)


func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(capturas_dir)
	await get_tree().create_timer(0.6).timeout
	var lista := []
	# comparación v13 / anime: mismo encuadre y misma hora (mediodía)
	for p in ["general", "profundidad", "copas", "vegetacion", "rocas", "terreno", "escala"]:
		for e in [Ajustes.ESTILO_ANIME, Ajustes.ESTILO_PICTORICO]:
			lista.append([e, 13.0, p])
	# ciclo día-noche en el plano general, en los dos estilos
	for h in [6.5, 9.0, 16.5, 18.2, 19.5, 21.0, 0.0]:
		for e in [Ajustes.ESTILO_ANIME, Ajustes.ESTILO_PICTORICO]:
			lista.append([e, h, "general"])
	for c in lista:
		if (not _solo.is_empty() and not (c[2] + "@" + str(c[1]) in _solo or (c[1] == 13.0 and c[2] in _solo))) or (_solo_estilo >= 0 and c[0] != _solo_estilo):
			continue
		Ajustes.contornos = true
		hora = c[1]
		aplicar_estilo(c[0])
		set_plano(c[2])
		await _shot("c2_%s_%s_h%s" % ["anime" if c[0] == Ajustes.ESTILO_ANIME else "v13", c[2], ("%04.1f" % float(c[1])).replace(".", "_")])
	get_tree().quit()


func _medir(fotogramas: int) -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for e in [Ajustes.ESTILO_PICTORICO, Ajustes.ESTILO_ANIME]:
		hora = 13.0
		aplicar_estilo(e)
		set_plano("general")
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
