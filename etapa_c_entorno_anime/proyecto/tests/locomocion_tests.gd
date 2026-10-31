extends RefCounted
## Pruebas de la caminata del Pollo Amarillo (PlayerCinematic) sobre un suelo plano, con las mismas
## entradas del jugador: los pies apoyados no patinan, las suelas no se hunden ni flotan, siempre hay un pie
## en el suelo al caminar y hay fase de vuelo al correr, las rodillas se doblan hacia delante, las botas
## apuntan hacia donde va el cuerpo y las transiciones no dan saltos. Las medidas salen del esqueleto
## animado (tests/tools/medidor_pisada.gd). No sustituyen a la revisión visual de los videos.
## Las ejecuta tests/e2e_director.gd en los modos all, unit y locomocion.

const JUGADOR := preload("res://scenes/characters/PlayerCinematic.tscn")

var results: Array = []
var resumen := {}


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas de locomoción del Pollo Amarillo ==")
	var raiz := Node3D.new()
	raiz.name = "PruebaLocomocion"
	tree.root.add_child(raiz)
	var suelo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(40, 1, 400)
	col.shape = caja
	col.position.y = -0.5
	suelo.add_child(col)
	raiz.add_child(suelo)
	var j: CinematicPlayer = JUGADOR.instantiate()
	raiz.add_child(j)
	j.place(Vector3(0, 0.05, 150), PI)
	j.view_basis = Basis()
	test_esqueleto(j)
	var m := MedidorPisada.new(j)
	await _secuencia(tree, j, m, [["asentar", 0.4, 0.0, false], ["quieto", 1.0, 0.0, false], ["arranque", 0.8, 1.0, false], ["caminar", 3.0, 1.0, false],
		["a_correr", 0.8, 1.0, true], ["correr", 2.5, 1.0, true], ["a_caminar", 1.0, 1.0, false], ["caminar2", 1.5, 1.0, false],
		["detenerse", 0.9, 0.0, false], ["quieto2", 0.8, 0.0, false]])
	for e in ["quieto", "caminar", "correr", "caminar2", "quieto2"]:
		resumen[e] = m.resumen(e)
	resumen["transiciones"] = {}
	for e in ["arranque", "a_correr", "a_caminar", "detenerse"]:
		resumen["transiciones"][e] = m.resumen(e)
	test_caminar(j, resumen["caminar"])
	test_correr(j, resumen["correr"])
	test_quieto(resumen["quieto"], resumen["quieto2"])
	test_transiciones(resumen["transiciones"], resumen["caminar2"])
	raiz.queue_free()
	await tree.process_frame
	return results


func _secuencia(tree: SceneTree, j: CinematicPlayer, m: MedidorPisada, pasos: Array) -> void:
	for p in pasos:
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
			# una muestra por fotograma procesado: la pose del esqueleto se actualiza en _process
			await tree.process_frame
			var dt := tree.root.get_process_delta_time()
			t += dt
			m.muestra(p[0], dt)
	Input.action_release("move_forward")
	Input.action_release("run")


func test_esqueleto(j: CinematicPlayer) -> void:
	var sk := MedidorPisada._buscar_esqueleto(j)
	check("Locomoción: el modelo conserva las 11 animaciones", ChickenVisual.ANIMS.all(func(a): return j.visual.has_anim(a)))
	# los huesos de la pierna siguen el eje de cada pierna de la malla (medido en Blender): rodilla y tobillo
	# dentro de la pernera y de la bota
	var esperado := {"shin.L": Vector3(0.19, 0.42, 0.05), "foot.L": Vector3(0.272, 0.115, 0.07),
		"shin.R": Vector3(-0.165, 0.42, -0.04), "foot.R": Vector3(-0.228, 0.115, -0.085)}
	var peor := 0.0
	for b in esperado:
		peor = maxf(peor, sk.get_bone_global_rest(sk.find_bone(b)).origin.distance_to(esperado[b]))
	check("Locomoción: rodillas y tobillos del esqueleto en el eje de cada pierna", peor < 0.01, "%.3f m" % peor)
	var l1 := sk.get_bone_global_rest(sk.find_bone("shin.L")).origin.distance_to(sk.get_bone_global_rest(sk.find_bone("thigh.L")).origin)
	var l2 := sk.get_bone_global_rest(sk.find_bone("foot.L")).origin.distance_to(sk.get_bone_global_rest(sk.find_bone("shin.L")).origin)
	check("Locomoción: muslo y espinilla proporcionados (0,9–1,1)", absf(l1 / l2 - 1.0) < 0.1, "%.3f / %.3f" % [l1, l2])
	var n_walk := j.visual.anim_length("walk")
	check("Locomoción: walk y run son ciclos (0,8 s y 0,53 s)", absf(n_walk - 0.8) < 0.02 and absf(j.visual.anim_length("run") - 16.0 / 30.0) < 0.02,
		"%.3f / %.3f" % [n_walk, j.visual.anim_length("run")])


func test_caminar(j: CinematicPlayer, r: Dictionary) -> void:
	print("  caminar: ", r)
	check("Caminar: velocidad de caminata", absf(r["velocidad_media"] - j.walk_speed) < 0.15, str(r["velocidad_media"]))
	check("Caminar: el pie apoyado no patina (<12 % de la velocidad)", r["desliz_pct_velocidad"] < 12.0, "%s %%" % r["desliz_pct_velocidad"])
	check("Caminar: siempre hay un pie en el suelo", r["pct_sin_pie_en_suelo"] < 3.0, "%s %%" % r["pct_sin_pie_en_suelo"])
	check("Caminar: las suelas no se hunden (>-1,5 cm)", r["suela_min_m"] > -0.015, "%s m" % r["suela_min_m"])
	check("Caminar: el pie más bajo no flota (<3 cm)", r["pie_mas_bajo_max_m"] < 0.03, "%s m" % r["pie_mas_bajo_max_m"])
	check("Caminar: rodillas hacia delante", r["pct_rodilla_no_al_frente"] < 3.0, "%s %%" % r["pct_rodilla_no_al_frente"])
	check("Caminar: flexión de rodilla anatómica (<100°)", r["flexion_rodilla_max"] < 100.0, "%s°" % r["flexion_rodilla_max"])
	check("Caminar: botas apoyadas hacia delante (media <12°)", r["punta_apoyada_desvio_medio"] < 12.0, "%s°" % r["punta_apoyada_desvio_medio"])


func test_correr(j: CinematicPlayer, r: Dictionary) -> void:
	print("  correr: ", r)
	check("Correr: velocidad de carrera", absf(r["velocidad_media"] - j.run_speed) < 0.2, str(r["velocidad_media"]))
	check("Correr: el pie apoyado no patina (<12 %)", r["desliz_pct_velocidad"] < 12.0, "%s %%" % r["desliz_pct_velocidad"])
	check("Correr: hay fase de vuelo (20–55 % sin pie en el suelo)", r["pct_sin_pie_en_suelo"] > 20.0 and r["pct_sin_pie_en_suelo"] < 55.0, "%s %%" % r["pct_sin_pie_en_suelo"])
	check("Correr: las suelas no se hunden (>-1,5 cm)", r["suela_min_m"] > -0.015, "%s m" % r["suela_min_m"])
	check("Correr: rodillas hacia delante", r["pct_rodilla_no_al_frente"] < 3.0, "%s %%" % r["pct_rodilla_no_al_frente"])
	check("Correr: botas apoyadas hacia delante (media <12°)", r["punta_apoyada_desvio_medio"] < 12.0, "%s°" % r["punta_apoyada_desvio_medio"])


func test_quieto(a: Dictionary, b: Dictionary) -> void:
	check("Quieto: botas plantadas sin hundirse ni moverse", a["suela_min_m"] > -0.008 and a["pie_mas_bajo_max_m"] < 0.01 and a["desliz_pie_apoyado_ms"] < 0.02,
		"%s / %s" % [a["suela_min_m"], a["pie_mas_bajo_max_m"]])
	check("Quieto tras detenerse: botas plantadas", b["suela_min_m"] > -0.008 and b["pie_mas_bajo_max_m"] < 0.01, "%s / %s" % [b["suela_min_m"], b["pie_mas_bajo_max_m"]])


func test_transiciones(t: Dictionary, caminar2: Dictionary) -> void:
	for e in t:
		var r: Dictionary = t[e]
		print("  transición ", e, ": ", r)
		# un tobillo en balanceo va a ~2-3 veces la velocidad del cuerpo; un salto de pose da picos mucho mayores
		check("Transición %s: sin saltos de pose (tobillo <9 m/s)" % e, r["vel_tobillo_max_ms"] < 9.0, "%s m/s" % r["vel_tobillo_max_ms"])
		# durante la mezcla (0,22–0,3 s) entre poses con alturas de pelvis y posiciones de pie distintas la
		# suela puede bajar unos centímetros un instante (pendiente: ajuste de pies en tiempo real)
		check("Transición %s: suelas sin hundirse (>-4 cm)" % e, r["suela_min_m"] > -0.04, "%s m" % r["suela_min_m"])
	check("Correr -> caminar: vuelve a caminar con un pie siempre apoyado", caminar2["pct_sin_pie_en_suelo"] < 3.0 and caminar2["desliz_pct_velocidad"] < 12.0,
		"%s %% / %s %%" % [caminar2["pct_sin_pie_en_suelo"], caminar2["desliz_pct_velocidad"]])
