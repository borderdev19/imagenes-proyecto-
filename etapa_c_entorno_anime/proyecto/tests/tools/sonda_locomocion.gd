extends Node
## Sonda de locomoción del Pollo Amarillo (PlayerCinematic tal cual, con las mismas entradas del jugador).
## Pruebas visuales de la caminata sobre un suelo plano cuadriculado, con cámaras fijas que solo se
## trasladan con el personaje (sin girar), para ver las articulaciones y el deslizamiento de los pies
## contra la cuadrícula; y el recorrido por el camino principal del entorno C3.
##
##   godot --path . --write-movie out.avi --fixed-fps 60 res://tests/tools/SondaLocomocion.tscn -- --prueba=A
##   (las vistas se reparten el ancho de la ventana del proyecto)
##   --prueba=A  caminata: vistas frontal, trasera y lateral
##   --prueba=B  carrera: vistas frontal y lateral
##   --prueba=C  transiciones quieto -> caminar -> correr -> caminar -> detenerse (lateral y frontal)
##   --prueba=D  recorrido por el camino principal de C3 (cámara al hombro + cámara baja a los pies)
##   --medir     sin video: imprime y guarda en user://locomocion_<prueba>.json las medidas de la pisada
##   --salida=ruta.json  otro destino para las medidas

const C3 := "res://scenes/pruebas/PruebaEntornoAnimeC3.tscn"
const JUGADOR := preload("res://scenes/characters/PlayerCinematic.tscn")

var prueba := "A"
var medir := false
var salida := ""
var jugador: CinematicPlayer
var medidor: MedidorPisada
var etapa := ""
var _camaras: Array = []
var _rotulo: Label
var _c3: Node
var _t := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prueba="):
			prueba = a.substr(9).to_upper()
		elif a == "--medir":
			medir = true
		elif a.begins_with("--salida="):
			salida = a.substr(9)
	GameState.test_mode = true
	Ajustes.persistir = false
	AudioManager.muted = true
	if prueba == "D":
		await _montar_c3()
	else:
		_montar_plano()
	medidor = MedidorPisada.new(jugador)
	_montar_paneles()
	await get_tree().create_timer(0.6).timeout
	match prueba:
		"A":
			await _secuencia([["quieto", 0.8, 0.0, false], ["caminar", 6.0, 1.0, false], ["detenerse", 1.2, 0.0, false]])
		"B":
			await _secuencia([["quieto", 0.6, 0.0, false], ["arranque", 1.2, 1.0, true], ["correr", 4.5, 1.0, true], ["detenerse", 1.2, 0.0, false]])
		"C":
			await _secuencia([["quieto", 1.2, 0.0, false], ["quieto_a_caminar", 1.0, 1.0, false], ["caminar", 2.0, 1.0, false],
				["caminar_a_correr", 1.0, 1.0, true], ["correr", 2.0, 1.0, true], ["correr_a_caminar", 1.0, 1.0, false],
				["caminar", 1.5, 1.0, false], ["caminar_a_quieto", 1.2, 0.0, false], ["quieto", 1.0, 0.0, false]])
		"D":
			await _recorrido_c3()
	var res := {}
	for e in _etapas():
		res[e] = medidor.resumen(e)
	res["todo"] = medidor.resumen()
	print("[locomocion] prueba ", prueba, " ", JSON.stringify(res, "  "))
	var f := FileAccess.open(salida if salida != "" else "user://locomocion_%s.json" % prueba, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(res, "  "))
	get_tree().quit()


func _etapas() -> Array:
	var out := []
	for m in medidor.muestras:
		if not out.has(m["t"]):
			out.append(m["t"])
	return out


func _montar_plano() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.74, 0.8, 0.86)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.environment.ambient_light_energy = 0.6
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 35, 0)
	sol.light_energy = 1.05
	sol.shadow_enabled = true
	add_child(sol)
	var suelo := StaticBody3D.new()
	suelo.collision_layer = 1
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(40, 1, 400)
	col.shape = caja
	col.position.y = -0.5
	suelo.add_child(col)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 400)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	# cuadrícula de 0,5 m con líneas cada metro más marcadas: el deslizamiento del pie se ve contra ella
	mat.shader.code = """shader_type spatial;
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 g = abs(fract(w.xz * 2.0 + 0.5) - 0.5) / fwidth(w.xz * 2.0);
	vec2 g1 = abs(fract(w.xz + 0.5) - 0.5) / fwidth(w.xz);
	float l = 1.0 - min(min(g.x, g.y), 1.0);
	float l1 = 1.0 - min(min(g1.x, g1.y), 1.0);
	ALBEDO = mix(mix(vec3(0.46, 0.45, 0.42), vec3(0.3, 0.29, 0.27), l * 0.7), vec3(0.12, 0.12, 0.11), l1);
	ROUGHNESS = 0.9;
}"""
	mi.material_override = mat
	suelo.add_child(mi)
	add_child(suelo)
	jugador = JUGADOR.instantiate()
	add_child(jugador)
	jugador.add_child(CombatStage.make_blob_shadow(0.45))
	jugador.place(Vector3(0, 0.05, 150), PI)
	# controles relativos a una cámara que mira a -z: "adelante" lleva al personaje hacia -z
	jugador.view_basis = Basis()


func _montar_c3() -> void:
	_c3 = (load(C3) as PackedScene).instantiate()
	add_child(_c3)
	await get_tree().create_timer(1.0).timeout
	_c3.hora = 13.0
	_c3.aplicar_estilo(Ajustes.ESTILO_ANIME)
	_c3.jugar(true)
	jugador = _c3.jugador


## Paneles: cada uno es un SubViewport del mismo mundo con su cámara. Las cámaras de la prueba en plano
## solo se trasladan con el personaje (no giran ni le siguen la orientación).
func _montar_paneles() -> void:
	var vistas: Array
	match prueba:
		"A":
			vistas = ["frontal", "trasera", "lateral"]
		"B":
			vistas = ["frontal", "lateral"]
		"C":
			vistas = ["lateral", "frontal"]
		_:
			vistas = ["hombro", "pies"]
	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	var capa := CanvasLayer.new()
	add_child(capa)
	capa.add_child(caja)
	for v in vistas:
		# los paneles se reparten el ancho de la ventana (el Movie Maker graba al tamaño del proyecto)
		var cont := SubViewportContainer.new()
		cont.stretch = true
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var sv := SubViewport.new()
		sv.world_3d = get_viewport().world_3d
		sv.msaa_3d = Viewport.MSAA_4X
		var cam := Camera3D.new()
		cam.fov = 32.0 if v != "hombro" else 60.0
		sv.add_child(cam)
		cont.add_child(sv)
		var et := Label.new()
		et.text = v.to_upper()
		et.position = Vector2(14, 10)
		et.add_theme_font_size_override("font_size", 22)
		et.add_theme_color_override("font_color", Color.WHITE)
		et.add_theme_color_override("font_outline_color", Color.BLACK)
		et.add_theme_constant_override("outline_size", 6)
		cont.add_child(et)
		caja.add_child(cont)
		_camaras.append([v, cam])
	_rotulo = Label.new()
	_rotulo.position = Vector2(14, get_viewport().get_visible_rect().size.y - 44)
	_rotulo.add_theme_font_size_override("font_size", 20)
	_rotulo.add_theme_color_override("font_color", Color.WHITE)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 6)
	capa.add_child(_rotulo)
	_colocar_camaras()


func _colocar_camaras() -> void:
	var p := jugador.global_position
	for par in _camaras:
		var v: String = par[0]
		var cam: Camera3D = par[1]
		match v:
			"frontal":
				cam.global_position = Vector3(0.0, 0.95, p.z - 5.5)
				cam.look_at(Vector3(0.0, 0.62, p.z), Vector3.UP)
			"trasera":
				cam.global_position = Vector3(0.0, 0.95, p.z + 5.5)
				cam.look_at(Vector3(0.0, 0.62, p.z), Vector3.UP)
			"lateral":
				cam.global_position = Vector3(5.5, 0.85, p.z)
				cam.look_at(Vector3(0.0, 0.62, p.z), Vector3.UP)
			"hombro":
				var c := get_viewport().get_camera_3d()
				if c:
					cam.global_transform = c.global_transform
			"pies":
				# cámara baja a la altura de los pies, al costado del camino, siguiendo al personaje
				var f := jugador.get_facing()
				var lado := f.cross(Vector3.UP).normalized()
				var objetivo := p + Vector3(0, 0.35, 0)
				var pos := objetivo + lado * 3.2 + Vector3(0, 0.15, 0)
				cam.global_position = cam.global_position.lerp(pos, 0.08) if _t > 0.1 else pos
				cam.look_at(objetivo, Vector3.UP)


func _process(delta: float) -> void:
	if jugador == null or medidor == null:
		return
	# una muestra por fotograma procesado: la pose del esqueleto se actualiza en _process
	_t += delta
	if etapa != "":
		medidor.muestra(etapa, delta)
	if _camaras.is_empty():
		return
	_colocar_camaras()
	var v := Vector2(jugador.velocity.x, jugador.velocity.z).length()
	_rotulo.text = "Prueba %s · %s · %.2f m/s · anim: %s ×%.2f" % [prueba, etapa, v, jugador.visual.current,
		jugador.visual.anim_player.speed_scale if jugador.visual.anim_player else 0.0]


## Cada paso: [etiqueta, segundos, empuje del joystick hacia delante, correr].
func _secuencia(pasos: Array) -> void:
	for p in pasos:
		etapa = p[0]
		var t := 0.0
		while t < p[1]:
			if p[2] > 0.0:
				Input.action_press("move_forward", p[2])
			else:
				Input.action_release("move_forward")
			if p[3]:
				Input.action_press("run")
			else:
				Input.action_release("run")
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
	Input.action_release("move_forward")
	Input.action_release("run")
	etapa = ""


## Recorrido por el camino principal de C3 con el piloto de la escena (mismas acciones del jugador).
func _recorrido_c3() -> void:
	etapa = "camino_caminar"
	_c3.pilotar(PruebaEntornoC3.puntos_camino(PruebaEntornoC3.INICIO_Z, -6.0))
	await _c3.esperar_ruta(30.0)
	etapa = "camino_correr"
	_c3.pilotar(PruebaEntornoC3.puntos_camino(-6.0, -20.0), true)
	await _c3.esperar_ruta(20.0)
	etapa = "camino_detenerse"
	await get_tree().create_timer(1.2).timeout
	etapa = ""
