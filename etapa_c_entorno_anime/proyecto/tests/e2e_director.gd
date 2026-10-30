extends Node
## Director de pruebas de extremo a extremo: juega el prototipo real (menú → selva → encuentro
## → diálogo → combate → victoria → regreso → revancha → derrota → reintento → menú) usando
## entradas simuladas, verifica cada paso y guarda capturas reales en res://screenshots/.

var mode := "all"
var take_shots := true
var results: Array = []
var shot_list: Array = []
var t_start := 0


func _ready() -> void:
	if take_shots:
		_set_fast_render(true)
	_run_suite.call_deferred()


func _run_suite() -> void:
	var t0 := Time.get_ticks_msec()
	var all: Array = []
	if mode in ["all", "unit"]:
		var u = preload("res://tests/unit_tests.gd").new()
		all += u.run_all()
	if mode in ["all", "unit", "anime"]:
		var a = preload("res://tests/anime_tests.gd").new()
		all += a.run_all(get_tree())
		var en = preload("res://tests/entorno_anime_tests.gd").new()
		all += en.run_all(get_tree())
		var c2 = preload("res://tests/entorno_c2_tests.gd").new()
		all += c2.run_all(get_tree())
		await run_laboratorio_anime()
	if mode in ["all", "parry", "e2e"]:
		await run_parry_window_tests()
	if mode in ["all", "e2e"]:
		await run_e2e()
	if mode in ["all", "mundo", "selva"]:
		await run_mundo()
	all += results
	var passed := all.filter(func(r): return r["ok"]).size()
	var failed := all.filter(func(r): return not r["ok"])
	var summary := {
		"godot_version": Engine.get_version_info()["string"],
		"renderer": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(),
		"mode": mode,
		"passed": passed,
		"failed": failed.size(),
		"wall_time_s": (Time.get_ticks_msec() - t0) / 1000.0,
		"results": all,
		"screenshots": shot_list,
	}
	var tag := mode + ("_headless" if DisplayServer.get_name() == "headless" else "_visual")
	var out_path := "res://tests/last_results_%s.json" % tag
	if not OS.has_feature("editor"):
		out_path = "user://last_results_%s.json" % tag
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(summary, "  "))
		f.close()
	print("\n==== RESULTADO: %d correctas, %d fallidas ====" % [passed, failed.size()])
	for r in failed:
		print("  FALLO: ", r["name"], "  ", r["detail"])
	get_tree().quit(0 if failed.is_empty() else 1)


## Laboratorio del estilo anime: la escena de prueba carga, monta todos sus objetos y alterna estilos.
func run_laboratorio_anime() -> void:
	print("== Laboratorio anime ==")
	var lab: PruebaAnime = (load(PruebaAnime.ESCENA) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	for i in 5:
		await get_tree().process_frame
	check("Laboratorio anime: esferas, madera, roca, follaje y los dos pollos montados",
		lab.stats.get("esferas", 0) == 6 and lab.stats.get("rocas", false) and lab.stats.get("follaje", false) and lab.amarillo != null and lab.negro != null and lab._objetos.size() >= 20,
		"objetos=%d" % lab._objetos.size())
	var anime_ok := true
	for o in lab._objetos:
		anime_ok = anime_ok and (o[0] as MeshInstance3D).get_surface_override_material(int(o[1])) == o[3]
	check("Laboratorio anime: arranca en estilo anime con contorno de pantalla", anime_ok and lab.estilo == Ajustes.ESTILO_ANIME
		and (lab.contorno_post == null or lab.contorno_post.visible))
	lab.aplicar_estilo(Ajustes.ESTILO_PICTORICO)
	var v13_ok := true
	for o in lab._objetos:
		v13_ok = v13_ok and (o[0] as MeshInstance3D).get_surface_override_material(int(o[1])) == o[2]
	check("Laboratorio anime: Tab vuelve al estilo pictórico v13 (materiales y filtro originales)", v13_ok and lab.look.visible and lab.we.environment == lab.env_v13)
	var c0: bool = Ajustes.contornos
	Ajustes.contornos = false
	lab.aplicar_estilo(Ajustes.ESTILO_ANIME)
	var apagados := true
	for o in lab._objetos:
		var am := o[3] as ShaderMaterial
		if am and am.next_pass is ShaderMaterial:
			apagados = apagados and not bool((am.next_pass as ShaderMaterial).get_shader_parameter("activo"))
	for mi in lab.amarillo.find_children("*", "MeshInstance3D", true, false):
		var pm := (mi as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		apagados = apagados and pm != null and pm.next_pass != null and not bool((pm.next_pass as ShaderMaterial).get_shader_parameter("activo"))
	check("Laboratorio anime: la opción Contornos apaga todos los contornos (personajes, esferas y pantalla)", apagados
		and (lab.contorno_post == null or not bool((lab.contorno_post.material_override as ShaderMaterial).get_shader_parameter("activo"))))
	Ajustes.contornos = c0
	lab.aplicar_estilo(Ajustes.ESTILO_ANIME)
	for h in PruebaAnime.HORAS:
		lab.set_hora(h)
	for i in PruebaAnime.SOLES.size():
		lab.set_sol(i)
	for n in PruebaAnime.PLANOS:
		lab.set_plano(n)
	await get_tree().process_frame
	check("Laboratorio anime: recorre horas, soles y encuadres sin errores", lab.plano == PruebaAnime.PLANOS.keys()[-1] and lab.sol_idx == PruebaAnime.SOLES.size() - 1)
	lab.queue_free()
	await get_tree().process_frame


func check(name: String, cond: bool, detail := "") -> bool:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))
	return cond


func wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func wait_until(cond: Callable, timeout := 10.0) -> bool:
	# tiempo de juego (no de pared): robusto con renderizado por software lento
	var t := 0.0
	while not cond.call():
		if t > timeout:
			return false
		await get_tree().process_frame
		t += get_process_delta_time()
	return true


func shot(file: String) -> void:
	if not take_shots:
		return
	_set_fast_render(false)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_set_fast_render(true)
	var path := "res://screenshots/" + file
	if not OS.has_feature("editor"):
		DirAccess.make_dir_recursive_absolute("user://screenshots")
		path = "user://screenshots/" + file
	var err := img.save_png(path)
	shot_list.append({"file": file, "size": "%dx%d" % [img.get_width(), img.get_height()], "ok": err == OK})
	print("  [SHOT] ", file, " ", img.get_width(), "x", img.get_height())


## Con renderizado por software (llvmpipe) la selva completa tarda segundos por fotograma.
## Entre capturas se ocultan vegetación y sombras (las colisiones son nodos aparte y siguen
## activas, así que la jugabilidad probada no cambia) y se baja la resolución 3D interna.
var _fast := false


func _set_fast_render(fast: bool) -> void:
	_fast = fast
	get_viewport().scaling_3d_scale = 0.35 if fast else 1.0
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if fast else Viewport.MSAA_2X
	var sc := get_tree().current_scene
	if sc == null:
		return
	var veg := sc.get_node_or_null("Vegetacion")
	if veg:
		veg.visible = not fast
	var sun := sc.get_node_or_null("Sol")
	if sun:
		(sun as DirectionalLight3D).shadow_enabled = not fast


func _process(_d: float) -> void:
	if take_shots and _fast:
		var sc := get_tree().current_scene
		if sc:
			var veg := sc.get_node_or_null("Vegetacion")
			if veg and veg.visible:
				_set_fast_render(true)


func scene() -> Node:
	return get_tree().current_scene


func action(name: String, pressed := true) -> void:
	var ev := InputEventAction.new()
	ev.action = name
	ev.pressed = pressed
	Input.parse_input_event(ev)


func tap(name: String) -> void:
	action(name, true)
	await frames(2)
	action(name, false)
	await frames(1)


func goto(path: String) -> void:
	SceneRouter.change_scene(path, 0.1, 0.1)
	await wait_until(func(): return scene() != null and scene().scene_file_path == path and not SceneRouter.is_busy(), 20.0)
	await frames(3)


# =================================================================== pruebas
func run_parry_window_tests() -> void:
	print("== Ventana de parada (tiempo real) ==")
	var pw := ParryWindow.new()
	add_child(pw)
	pw.open(0.5)
	await wait(0.05)
	pw.press()
	check("Parada: pulsar demasiado pronto falla (early)", pw.result == "early")
	pw.press()
	check("Parada: se resuelve una sola vez por ataque", pw.result == "early")
	pw.open(0.3)
	await wait(0.25)
	pw.press()
	check("Parada: pulsar dentro de la ventana es perfecta", pw.result == "perfect")
	pw.open(0.2)
	var r: String = await pw.wait_result()
	check("Parada: no pulsar se resuelve como tarde (late) sin bloquear", r == "late")
	pw.queue_free()


func run_e2e() -> void:
	print("== Recorrido completo (extremo a extremo) ==")
	# ------------------------------------------------ menú
	await goto(GameState.SCENE_MENU)
	await wait(1.5)
	check("Menú inicial cargado", scene() is MainMenu)
	await shot("01_menu_inicial.png")
	var menu := scene() as MainMenu
	var btns := _find_buttons(menu)
	check("Menú tiene Jugar, Controles y Salir (sin Selva clásica)", btns.has("Jugar") and btns.has("Controles") and btns.has("Salir") and not btns.has("Selva clásica"), str(btns.keys()))
	_check_ui_above_filter(scene(), "menú")
	(btns["Controles"] as Button).pressed.emit()
	await wait(0.3)
	check("Botón Controles muestra el panel", menu._controls.visible)
	await shot("01b_menu_controles.png")
	(btns["Controles"] as Button).pressed.emit()
	check("Menú tiene Opciones", btns.has("Opciones"))
	if btns.has("Opciones"):
		(btns["Opciones"] as Button).pressed.emit()
		await wait(0.3)
		check("Botón Opciones muestra el panel (calidad, partículas, filtro)", menu._options.visible and menu._options._rows.has("calidad") and menu._options._rows.has("particulas") and menu._options._rows.has("filtro"))
		var q0: int = Ajustes.calidad
		(menu._options._rows["calidad"] as Button).pressed.emit()
		check("Opciones: cambiar la calidad desde el panel", Ajustes.calidad == (q0 + 1) % Ajustes.CALIDADES.size())
		await shot("01c_menu_opciones.png")
		Ajustes.set_valor("calidad", q0)
		(btns["Opciones"] as Button).pressed.emit()
	(btns["Jugar"] as Button).pressed.emit()
	var ok := await wait_until(func(): return scene() is Mundo3D and not SceneRouter.is_busy(), 40.0)
	check("Jugar carga el mundo 3D (Árbol del Eco)", ok)
	var level := scene() as Mundo3D
	var p := level.player
	check("El Pollo Amarillo aparece", p != null and p.visual != null and p.visual.anim_player != null)
	await wait_until(func(): return level.dialogue.active, 8.0)
	await _advance_dialogue(level.dialogue)
	# atajo: ofrenda entregada (el recorrido completo nido -> estatua se prueba en run_mundo)
	GameState.village_reached = true
	GameState.reveal_seen = true
	GameState.offering_given = true
	await goto(GameState.SCENE_MUNDO)
	level = scene() as Mundo3D
	p = level.player
	await wait(0.5)
	check("Con la ofrenda entregada la cortina del Guardián está abierta y el Pollo Negro espera", level.curtain_open and level.enemy.visible)
	p.place(level.datos.marker("enemigo") + Vector3(0, 0.3, -7.5), 0.0)
	await wait(0.4)
	# primera vez en el claro: comentario del Pollo Amarillo ante la estatua
	if level.dialogue.active:
		await _advance_dialogue(level.dialogue)
	# ------------------------------------------------ encuentro
	ok = await wait_until(func():
		if not GameState.encounter_triggered:
			_steer_towards(p, level.enemy.global_position)
		return GameState.encounter_triggered, 8.0)
	_release_moves()
	check("El encuentro se activa al acercarse al Pollo Negro", ok and GameState.encounter_triggered)
	check("El movimiento se bloquea durante el encuentro", not p.input_enabled)
	ok = await wait_until(func(): return level.dialogue.active, 8.0)
	check("Aparece el diálogo entre ambos pollos", ok)
	var shown := [0]
	level.dialogue.line_shown.connect(func(_i): shown[0] += 1)
	await wait(1.3)
	await shot("04_encuentro_dialogo.png")
	# anti-salto: pulsaciones rápidas no deben saltar líneas
	var idx0: int = level.dialogue._index
	for k in 6:
		level.dialogue.advance()
	await frames(2)
	check("Pulsaciones rápidas no saltan el diálogo completo", level.dialogue._index <= idx0 + 1 and level.dialogue.active, "índice %d -> %d" % [idx0, level.dialogue._index])
	var lines_before: Array = level.dialogue._lines
	var idx_before: int = level.dialogue._index
	level.start_encounter(false)
	await frames(2)
	check("El encuentro no se duplica (llamadas repetidas ignoradas)", level.dialogue._lines == lines_before and level.dialogue._index == idx_before and level.mode == Mundo3D.Mode.DIALOGUE)
	await _advance_dialogue(level.dialogue)
	check("El diálogo avanza y termina (5 líneas)", shown[0] + 1 >= 5, "líneas mostradas=%d" % (shown[0] + 1))
	ok = await wait_until(func(): return scene() is CombatScene and not SceneRouter.is_busy(), 15.0)
	check("Transición cinematográfica al combate", ok)
	# ------------------------------------------------ combate
	await _combat_flow(true)
	# ------------------------------------------------ continuar exploración tras victoria
	var cs := scene() as CombatScene
	cs.hud.result_choice.emit("continue")
	ok = await wait_until(func(): return scene() is Mundo3D and not SceneRouter.is_busy(), 30.0)
	check("Continuar regresa a la exploración", ok)
	await wait(1.2)
	level = scene() as Mundo3D
	p = level.player
	var near := p.global_position.distance_to(level.enemy.global_position)
	check("El jugador reaparece en el claro", near < 8.0, "%.1f m del enemigo" % near)
	ok = await wait_until(func(): return level.dialogue.active, 6.0)
	check("Diálogo tras la victoria", ok)
	await _advance_dialogue(level.dialogue)
	check("El encuentro no se repite automáticamente", level.mode == Mundo3D.Mode.EXPLORE and p.input_enabled)
	await wait(0.5)
	await shot("09a_regreso_exploracion_revancha.png")
	check("Aparece la opción de revancha (E)", level._current_interactable.get("id", "") == "revancha")
	await tap("interact")
	ok = await wait_until(func(): return level.dialogue.active, 8.0)
	check("La revancha inicia el encuentro de nuevo (ciclo repetible)", ok)
	await _advance_dialogue(level.dialogue)
	ok = await wait_until(func(): return scene() is CombatScene and not SceneRouter.is_busy(), 15.0)
	check("Segundo combate cargado sin reiniciar el proyecto", ok)
	# ------------------------------------------------ derrota y reintento
	await _combat_flow(false)
	cs = scene() as CombatScene
	var old_id := cs.get_instance_id()
	cs.hud.result_choice.emit("retry")
	ok = await wait_until(func(): return scene() is CombatScene and scene().get_instance_id() != old_id and not SceneRouter.is_busy(), 15.0)
	check("Reintentar recarga el combate", ok)
	cs = scene() as CombatScene
	ok = await wait_until(func(): return (scene() as CombatScene).controller.state == BattleController.State.PLAYER_TURN, 10.0)
	var cc := cs.controller
	check("Reintentar restaura HP/POW y estados", ok and cc.hero.hp == cc.hero.max_hp and cc.enemy.hp == cc.enemy.max_hp and cc.turn == 1 and cc.hero.power == cc.hero.data.start_power and cc.enemy.power == cc.enemy.data.start_power and not cc.hero.guarding and not cc.enemy.charging)
	# reinicios consecutivos desde la pausa
	for k in 2:
		await tap("pause")
		await wait(0.3)
		var prev_id := cs.get_instance_id()
		cs.pause_menu._on_restart()
		ok = await wait_until(func(): return scene() is CombatScene and scene().get_instance_id() != prev_id and not SceneRouter.is_busy(), 15.0)
		cs = scene() as CombatScene
		var ok_turn := await wait_until(func(): return (scene() as CombatScene).controller.state == BattleController.State.PLAYER_TURN, 10.0)
		ok = ok and ok_turn
	check("Reinicios consecutivos sin estados colgados", ok and not get_tree().paused)
	# volver al menú
	await tap("pause")
	await wait(0.3)
	cs.pause_menu._on_menu()
	ok = await wait_until(func(): return scene() is MainMenu and not SceneRouter.is_busy(), 15.0)
	check("Volver al menú desde la pausa", ok and not get_tree().paused)


## Arena 3D: escenario cargado, cámara sobre el hombro en el turno del jugador y personajes en pantalla.
func _check_combat_camera(cs: CombatScene) -> void:
	var st := cs.stage
	check("Combate en el claro de la Estatua del mundo 3D", st.use_world and st.world != null and int(st.world.stats.get("instancias", 0)) > 5000 and st.stage_center.distance_to(st.world_data.marker("claro")) < 12.0, str(st.stage_center))
	check("Turno del jugador: cámara sobre el hombro del héroe", st.current_shot == "hombro_heroe", st.current_shot)
	var cam := st.camera
	var d := cam.global_position.distance_to(cs.hero_node.global_position)
	check("Cámara cerca del héroe (tercera persona, < 4 m de sus pies)", d < 4.0, "%.2f m" % d)
	var hp := st.screen_pos(cs.hero_node.global_position + Vector3(0, 1.2, 0))
	var vr := cs.get_viewport().get_visible_rect().size
	check("El héroe se ve en primer plano a un lado (sobre el hombro)", Rect2(Vector2.ZERO, vr).has_point(hp) and hp.x < vr.x * 0.5, str(hp))
	var vp := cs.get_viewport().get_visible_rect().size
	var ep := st.screen_pos(cs.enemy_node.global_position + Vector3(0, 0.6, 0))
	check("El enemigo se ve en el plano del hombro", not cam.is_position_behind(cs.enemy_node.global_position) and Rect2(Vector2.ZERO, vp).has_point(ep), str(ep))
	check("Combate: filtro pictórico activo", st.look != null and st.look.is_active())
	_check_ui_above_filter(cs, "combate")
	GameState.painterly_filter = false
	var off := not st.look.is_active()
	GameState.painterly_filter = true
	check("El filtro pictórico se puede desactivar y volver a activar", off and st.look.is_active())
	print("    renderizador: ", RenderingServer.get_current_rendering_method())


## Ninguna interfaz debe quedar por debajo del filtro pictórico (se vería borrosa y pintada).
func _check_ui_above_filter(root: Node, label: String) -> void:
	var bad: Array[String] = []
	for n in root.find_children("*", "CanvasLayer", true, false):
		if n is CinematicLook:
			continue
		var has_ui := not n.find_children("*", "Control", true, false).is_empty()
		if has_ui and (n as CanvasLayer).layer <= 5:
			bad.append("%s(%d)" % [n.name, (n as CanvasLayer).layer])
	check("Interfaz por encima del filtro pictórico: " + label, bad.is_empty(), str(bad))


func _combat_flow(win: bool) -> void:
	var cs := scene() as CombatScene
	var c := cs.controller
	var ok := await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 15.0)
	check("Combate iniciado: turno del jugador", ok)
	await wait(1.0)
	check("Turno del jugador: aparece la mano de cartas", cs.hud._hand.shown and cs.hud._hand.visible)
	if win:
		await shot("05_combate_personajes.png")
	check("HUD conectado a valores reales (HP)", _hud_text(cs, "hero").contains("%d/%d" % [c.hero.hp, c.hero.max_hp]))
	if win:
		_check_combat_camera(cs)
		# ---------------- ATAQUE + entradas rápidas
		var e0 := c.enemy.hp
		var ev0 := c.damage_events
		var b: Button = cs.hud._buttons["attack"]
		b.pressed.emit()
		for k in 5:
			b.pressed.emit()
			await tap("cmd_attack")
		await wait_until(func(): return c.enemy.hp < e0, 5.0)
		check("Ataque: corte al plano de impacto", cs.stage.current_shot == "impacto", cs.stage.current_shot)
		check("Fuera del turno del jugador no hay cartas ni botones", not cs.hud._hand.shown)
		await shot("07_ataque_impacto.png")
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN or c.state >= BattleController.State.VICTORY, 10.0)
		check("ATAQUE: daño real al enemigo", c.enemy.hp < e0, "%d -> %d" % [e0, c.enemy.hp])
		var player_hits := 0
		check("Pulsaciones repetidas no duplican el daño (1 golpe del jugador)", c.history.filter(func(h): return h.begins_with("¡Pollo Amarillo lanza")).size() == 1)
		await wait(0.3)
		await shot("06_interfaz_combate_valores.png")
		# ---------------- DEFENSA
		c.ai.charge_chance = 0.0
		c.ai.defend_chance = 0.0
		var h0 := c.hero.hp
		cs.hud._buttons["defend"].pressed.emit()
		await wait(0.2)
		check("DEFENSA activa la guardia (DEF sube a 16)", c.hero.guarding and c.hero.defense_total() == 16 and _hud_text(cs, "hero").contains("16/16"))
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 10.0)
		check("DEFENSA: el daño recibido se reduce", h0 - c.hero.hp <= 9, "daño=%d" % (h0 - c.hero.hp))
		# ---------------- PARADA perfecta (entrada real por InputEvent)
		var h1 := c.hero.hp
		var e1 := c.enemy.hp
		cs.hud._buttons["parry"].pressed.emit()
		await wait_until(func(): return cs.parry.active, 6.0)
		await wait_until(func(): return cs.parry.in_window(), 4.0)
		check("Ataque enemigo: plano a la espalda del enemigo", cs.stage.current_shot == "hombro_enemigo", cs.stage.current_shot)
		await shot("07b_parada_ventana.png")
		action("parry", true)
		await frames(1)
		action("parry", false)
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 10.0)
		check("PARADA acertada: sin daño y con contraataque", c.hero.hp == h1 and c.enemy.hp < e1 and cs.parry.result == "perfect", "%s hp %d->%d" % [cs.parry.result, h1, c.hero.hp])
		# ---------------- PARADA fallida
		var h2 := c.hero.hp
		cs.hud._buttons["parry"].pressed.emit()
		await wait_until(func(): return cs.parry.active, 6.0)
		action("parry", true)
		await frames(1)
		action("parry", false)
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 10.0)
		check("PARADA fallida: resultado distinto (recibe daño)", c.hero.hp < h2 and cs.parry.result == "early", "%s hp %d->%d" % [cs.parry.result, h2, c.hero.hp])
		# ---------------- PODER
		if c.hero.power < 50:
			c.hero.power = 60
			cs._refresh_stats()
		var pw0 := c.hero.power
		var e2 := c.enemy.hp
		var dev0 := c.damage_events
		await wait(0.2)
		check("Botón PODER habilitado con POW suficiente", not (cs.hud._buttons["power"] as Button).disabled)
		cs.hud._buttons["power"].pressed.emit()
		await wait(0.2)
		check("PODER consume 50 POW", c.hero.power == pw0 - 50, "%d -> %d" % [pw0, c.hero.power])
		await wait(0.55)
		await shot("07c_poder_especial.png")
		var sp: CinematicaHabilidad = cs.super_attack
		check("Súper ataque: cinemática en marcha (sin HUD, con franjas de cine)", sp != null and sp.running and not cs.hud.visible and sp.overlay != null)
		await wait_until(func(): return not is_instance_valid(sp) or "ojos" in sp.shots_used, 6.0)
		if is_instance_valid(sp) and "ojos" in sp.shots_used:
			await shot("07d_super_ojos.png")
		await wait_until(func(): return c.enemy.hp < e2, 8.0)
		check("PODER causa daño elevado", e2 - c.enemy.hp >= 30, "daño=%d" % (e2 - c.enemy.hp))
		var hero_hab: HabilidadCinematica = sp.hab if is_instance_valid(sp) else null
		check("Habilidad del héroe definida por datos (Pluma Ígnea)", hero_hab != null and hero_hab.id == "pluma_ignea" and hero_hab.elemento == "fuego")
		var used: Array = sp.shots_used.duplicate() if is_instance_valid(sp) else []
		check("Súper ataque: pasa por activación, vuelta, ojos, espalda y rival", is_instance_valid(sp) and ["activacion_a", "vuelta_a", "ojos", "espalda", "rival"].all(func(n): return n in used), str(used))
		check("Súper ataque: al terminar vuelve el HUD y la velocidad normal", cs.hud.visible and is_equal_approx(Engine.time_scale, 1.0))
		await wait(0.5)
		check("Habilidad cinematográfica: el daño se aplica una sola vez", c.damage_events == dev0 + 1, "eventos=%d" % (c.damage_events - dev0))
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 10.0)
		var saved_pow := c.hero.power
		c.hero.power = 10
		cs._refresh_stats()
		await frames(2)
		var e3 := c.enemy.hp
		var refused := not c.request_action("power")
		check("PODER bloqueado sin POW suficiente (botón deshabilitado y acción rechazada)", (cs.hud._buttons["power"] as Button).disabled and refused and c.enemy.hp == e3 and c.state == BattleController.State.PLAYER_TURN)
		c.hero.power = saved_pow
		cs._refresh_stats()
		# ---------------- GARRA SOMBRÍA del enemigo (misma estructura de habilidades) + parada perfecta
		c.hero.hp = c.hero.max_hp
		c.enemy.hp = c.enemy.max_hp
		c.enemy.charging = true
		cs._refresh_stats()
		await frames(2)
		var h3 := c.hero.hp
		var dev1 := c.damage_events
		cs.hud._buttons["parry"].pressed.emit()
		var started := await wait_until(func(): return is_instance_valid(cs.enemy_ability) and cs.enemy_ability.running, 8.0)
		var enemy_hab: HabilidadCinematica = cs.enemy_ability.hab if started else null
		check("Garra Sombría: cinemática del enemigo en marcha (sin ventana de parada aún)", started and not cs.parry.active)
		if started:
			await wait_until(func(): return not is_instance_valid(cs.enemy_ability) or "ojos" in cs.enemy_ability.shots_used, 5.0)
			await shot("07e_garra_sombria_preludio.png")
		var opened := await wait_until(func(): return cs.parry.active, 8.0)
		check("Garra Sombría: la ventana de parada se abre tras el preludio, con el HUD visible", opened and cs.hud.visible)
		await wait_until(func(): return cs.parry.in_window(), 4.0)
		await shot("07f_garra_sombria_parada.png")
		action("parry", true)
		await frames(1)
		action("parry", false)
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 10.0)
		check("Garra Sombría parada: sin daño, contraataque y un solo evento de daño", c.hero.hp == h3 and cs.parry.result == "perfect" and c.damage_events == dev1 + 1, "%s hp %d->%d eventos=%d" % [cs.parry.result, h3, c.hero.hp, c.damage_events - dev1])
		check("Garra Sombría: termina sin bloquear (HUD, velocidad normal, turno del jugador)", cs.hud.visible and is_equal_approx(Engine.time_scale, 1.0) and c.state == BattleController.State.PLAYER_TURN)
		# misma habilidad sin parada: el daño entra una vez y es mayor que un picotazo
		c.enemy.charging = true
		var h4 := c.hero.hp
		var dev2 := c.damage_events
		cs.hud._buttons["defend"].pressed.emit()
		await wait_until(func(): return c.state == BattleController.State.PLAYER_TURN, 15.0)
		check("Garra Sombría recibida en guardia: un solo evento de daño", c.hero.hp < h4 and c.damage_events == dev2 + 1, "hp %d->%d eventos=%d" % [h4, c.hero.hp, c.damage_events - dev2])
		check("Habilidad del enemigo definida por datos (Garra Sombría, elemento sombra)", enemy_hab != null and enemy_hab.id == "garra_sombria" and enemy_hab.elemento == "sombra")
		c.hero.hp = c.hero.max_hp
		cs._refresh_stats()
		# ---------------- pausa
		await tap("pause")
		await wait(0.3)
		check("Esc pausa el combate", get_tree().paused and cs.pause_menu.is_open())
		await shot("10_pausa.png")
		await tap("pause")
		await wait(0.3)
		check("Esc reanuda", not get_tree().paused)
		# ---------------- victoria
		c.enemy.hp = 1
		cs._refresh_stats()
		cs.hud._buttons["attack"].pressed.emit()
		var ok2 := await wait_until(func(): return cs.hud.has_result_panel(), 15.0)
		check("Pantalla de VICTORIA al vaciar el HP enemigo", ok2 and c.state == BattleController.State.VICTORY and GameState.victories >= 1)
		await wait(0.9)
		await shot("08_victoria.png")
	else:
		await wait(0.3)
		c.ai.charge_chance = 0.0
		c.ai.defend_chance = 0.0
		c.hero.hp = 1
		cs._refresh_stats()
		cs.hud._buttons["attack"].pressed.emit()
		var ok3 := await wait_until(func(): return cs.hud.has_result_panel(), 15.0)
		check("Pantalla de DERROTA al vaciar el HP del protagonista", ok3 and c.state == BattleController.State.DEFEAT and GameState.defeats >= 1)
		await wait(0.9)
		await shot("09_derrota.png")
	check("Máquina de estados sin transiciones inválidas", c.invalid_transitions == 0)


func _hud_text(cs: CombatScene, id: String) -> String:
	var rows: Dictionary = cs.hud._panels[id]["rows"]
	return "%s %s %s" % [(rows["hp"][1] as Label).text, (rows["def"][1] as Label).text, (rows["pow"][1] as Label).text]


func _advance_dialogue(d: DialogueBox) -> void:
	var guard := 0
	while d.active and guard < 40:
		guard += 1
		await wait(0.32)
		d.advance()
	await wait(0.3)


func _find_buttons(n: Node, out := {}) -> Dictionary:
	if n is Button:
		out[(n as Button).text] = n
	for c in n.get_children():
		_find_buttons(c, out)
	return out


# =================================================================== selva cinematográfica
## Mantiene el joystick (acciones analógicas) apuntando hacia un punto del mundo, relativo a la
## cámara fija activa, igual que haría un jugador. Devuelve la intensidad aplicada.
func _steer_towards(p: CinematicPlayer, target: Vector3, strength := 1.0) -> void:
	var d := target - p.global_position
	d.y = 0
	if d.length() < 0.05:
		_release_moves()
		return
	d = d.normalized()
	# la base que usa realmente el personaje (tras un corte conserva la anterior mientras se mantenga el stick)
	var b := p._held_basis if p._holding else p.view_basis
	var fwd := -b.z
	fwd.y = 0
	fwd = fwd.normalized()
	var right := b.x
	right.y = 0
	right = right.normalized()
	_stick(Vector2(d.dot(right), -d.dot(fwd)) * strength)


func _stick(v: Vector2) -> void:
	for pair in [["move_right", maxf(v.x, 0.0)], ["move_left", maxf(-v.x, 0.0)], ["move_back", maxf(v.y, 0.0)], ["move_forward", maxf(-v.y, 0.0)]]:
		var ev := InputEventAction.new()
		ev.action = pair[0]
		ev.pressed = pair[1] > 0.01
		ev.strength = pair[1]
		Input.parse_input_event(ev)


func _release_moves() -> void:
	_stick(Vector2.ZERO)


## Video del iPhone (v7): junto a la entrada del puente de piedra el pollo caía por el borde del cenote y
## se quedaba atrapado sin poder moverse. Empuja hacia los huecos a ambos lados del puente y comprueba que
## no cae; después lo deja caer a propósito en el borde y comprueba que vuelve a un punto seguro.
func _check_cenote_edge(level: Mundo3D) -> void:
	var p := level.player
	action("run", true)
	var worst := 99.0
	var all_ok := true
	# el segundo punto vuelve a (42.3, 10.8): desde ahí, hacia (41.6, 12.8), el código anterior caía
	for target in [Vector3(41.0, 0, 13.5), Vector3(42.3, 0, 10.8), Vector3(41.6, 0, 12.8), Vector3(42.3, 0, 12.4), Vector3(46.0, 0, 12.5)]:
		var t := 0.0
		while t < 2.0:
			if level.mode != Mundo3D.Mode.EXPLORE:
				_release_moves()
				if level.dialogue.active:
					level.dialogue.advance()
				await wait(0.2)
				t += 0.2
				continue
			_steer_towards(p, target)
			await frames(1)
			t += get_process_delta_time()
			worst = minf(worst, p.global_position.y)
			if not level._walkable(p.global_position):
				all_ok = false
		_release_moves()
		await wait(0.2)
	action("run", false)
	# mismo empuje que reprodujo la caída con la sonda (movimiento dirigido desde (42.3, 10.8))
	p.place(Vector3(42.3, 0.4, 10.8), 0.0)
	await frames(2)
	for i in 90:
		p._auto_target = Vector3(41.6, 0.4, 12.8)
		await frames(1)
		worst = minf(worst, p.global_position.y)
		if not level._walkable(p.global_position):
			all_ok = false
	p._auto_target = Vector3.INF
	check("Borde del cenote junto al puente: el personaje no cae al empujar hacia los huecos", all_ok and worst > -0.6, "y mínima=%.2f" % worst)
	# caída forzada sobre el talud del cenote: debe volver solo a un punto caminable
	var safe := p.global_position
	p.global_position = Vector3(41.92, -1.24, 11.78)   # donde quedaba encajado en la prueba con el código anterior
	p.velocity = Vector3.ZERO
	var back := await wait_until(func(): return level._walkable(p.global_position) and p.global_position.distance_to(safe) < 1.0, 2.0)
	check("Si cae fuera de la zona caminable, vuelve solo al último punto seguro", back, str(p.global_position.snapped(Vector3.ONE * 0.01)))
	var from := p.global_position
	_steer_towards(p, Vector3(40.0, 0, 9.0))
	await wait(0.5)
	_release_moves()
	check("Tras volver puede seguir moviéndose", back and level._walkable(p.global_position) and p.global_position.distance_to(from) > 0.3, str(p.global_position.snapped(Vector3.ONE * 0.01)))


func _talk_at(level: Mundo3D, target: Vector3, label: String) -> bool:
	await wait(0.4)
	var prompt_ok := not level._current_interactable.is_empty()
	await tap("interact")
	var ok := await wait_until(func(): return level.dialogue.active, 4.0)
	check("Interacción: " + label + " (aviso + diálogo)", prompt_ok and ok, "aviso=%s" % prompt_ok)
	return ok


## Cámara en tercera persona sobre el hombro: cerca del personaje (ni lejos ni pegada) y por detrás.
func _check_shoulder(level: Mundo3D, label: String) -> void:
	var p := level.player
	var d := level.cam.global_position.distance_to(p.global_position + Vector3(0, 1.45, 0))
	check("Cámara al hombro: " + label, level.director.current == "hombro" and d > 0.8 and d < 4.5, "%s %.2f m" % [level.director.current, d])


## Giro manual de la cámara (Q/R, J/L o stick derecho) y vuelta al seguimiento.
func _check_camera_turn(level: Mundo3D) -> void:
	var y0 := level.director.yaw
	action("cam_left", true)
	await wait(0.5)
	action("cam_left", false)
	var y1 := level.director.yaw
	check("Cámara al hombro: se gira a mano", absf(wrapf(y1 - y0, -PI, PI)) > 0.5, "%.2f -> %.2f" % [y0, y1])
	await frames(2)
	_check_visible(level, "tras girar la cámara")
	await _check_camera_still(level)


## Con el joystick suelto la cámara no debe girar sola (fallo del video: daba vueltas parado en la rama).
func _check_camera_still(level: Mundo3D) -> void:
	var p := level.player
	var back := p.global_position
	var back_f := float(p.facing_yaw)
	var pts := {"rama_tronco": Vector3(10.8, 12.0, -40.3), "rama_medio": Vector3(15.0, 12.0, -40.1),
		"rama_punta": Vector3(21.2, 12.0, -39.8), "puente_inicio": level.datos.marker("puente_inicio")}
	# anillo de pasarelas alrededor del tronco (donde se grabó el fallo): puntos caminables cada 30°
	for r in [8.5, 9.5, 10.5]:
		for deg in range(0, 360, 30):
			var a := deg_to_rad(float(deg))
			var q := Vector3(sin(a) * r, 12.0, -40.0 + cos(a) * r)
			if level.datos.is_walkable(q) and not pts.values().any(func(v): return v.distance_to(q) < 2.0):
				pts["anillo_%d_%d" % [int(r * 10), deg]] = q
	var worst := 0.0
	var where := ""
	for k in pts:
		_release_moves()
		p.place(pts[k] + Vector3(0, 0.3, 0), 0.0)
		await wait(2.5)
		var y0 := level.director.yaw
		await wait(3.0)
		var d := absf(wrapf(level.director.yaw - y0, -PI, PI))
		if d > worst:
			worst = d
			where = k
	check("Cámara quieta con el joystick suelto (rama madre y anillo)", worst < 0.05, "%d puntos, máx %.3f rad en %s" % [pts.size(), worst, where])
	p.place(back, back_f)
	await wait(0.6)


## El personaje debe verse dentro del encuadre fijo (no fuera de cámara ni detrás de ella).
func _check_visible(level: Mundo3D, label: String) -> bool:
	var p := level.player
	var pos := p.global_position + Vector3(0, 0.7, 0)
	var vp := level.get_viewport().get_visible_rect().size
	var behind := level.cam.is_position_behind(pos)
	var sp := level.cam.unproject_position(pos)
	var inside := not behind and sp.x > 20 and sp.x < vp.x - 20 and sp.y > 20 and sp.y < vp.y - 20
	return check("Personaje dentro del encuadre: " + label, inside, "pantalla=(%d, %d)" % [sp.x, sp.y])


## Camina con el joystick por una lista de puntos (como un jugador). Cuenta los fotogramas en los que el
## personaje queda fuera de cuadro y los planos de cámara vistos. Devuelve false si se atasca.
var _off_frames := 0
var _shots_seen := {}


func _walk_route(level: Mundo3D, pts: Array, label: String, run := false, radius := 0.7, timeout := 90.0, auto_dialogue := true) -> bool:
	var p := level.player
	var i := 0
	var t := 0.0
	var last_prog := p.global_position
	var stuck_t := 0.0
	if run:
		action("run", true)
	while i < pts.size() and t < timeout:
		if level.mode != Mundo3D.Mode.EXPLORE:
			_release_moves()
			if not auto_dialogue:
				break
			# diálogos de zona (rama, cenote, orquídea...): se leen y se sigue andando
			if level.dialogue.active:
				await wait(0.3)
				level.dialogue.advance()
			else:
				await frames(1)
			t += get_process_delta_time()
			continue
		var target: Vector3 = pts[i]
		var d := Vector2(target.x - p.global_position.x, target.z - p.global_position.z).length()
		if d < radius:
			i += 1
			continue
		_steer_towards(p, target)
		await frames(1)
		t += get_process_delta_time()
		_shots_seen[level.director.current] = true
		var sp := level.cam.unproject_position(p.global_position + Vector3(0, 0.7, 0))
		if level.cam.is_position_behind(p.global_position + Vector3(0, 0.7, 0)) or not level.get_viewport().get_visible_rect().has_point(sp):
			_off_frames += 1
		if p.global_position.distance_to(last_prog) > 0.4:
			last_prog = p.global_position
			stuck_t = 0.0
		else:
			stuck_t += get_process_delta_time()
			if stuck_t > 4.0:
				break
	_release_moves()
	if run:
		action("run", false)
	if not auto_dialogue and level.mode != Mundo3D.Mode.EXPLORE:
		return check("Recorrido a pie: " + label, true)
	return check("Recorrido a pie: " + label, i >= pts.size(), "punto %d/%d en %s, %.1f s (modo=%d entrada=%s auto=%s vel=%s)" % [i, pts.size(), str(p.global_position.snapped(Vector3.ONE * 0.1)), t, level.mode, p.input_enabled, p._auto_target, p.velocity.snapped(Vector3.ONE * 0.01)])


func _interact_here(level: Mundo3D, id: String, label: String) -> bool:
	await wait(0.3)
	var prompt_ok: bool = level._current_interactable.get("id", "") == id
	await tap("interact")
	var ok := await wait_until(func(): return level.dialogue.active, 5.0)
	check("Interacción: " + label + " (aviso + diálogo)", prompt_ok and ok, "aviso=%s actual=%s" % [prompt_ok, level._current_interactable.get("id", "-")])
	return ok


func _v3list(a: Array) -> Array:
	var out := []
	for q in a:
		out.append(Vector3(q[0], 0.0, q[1]) if q.size() == 2 else Vector3(q[0], q[1], q[2]))
	return out


func run_mundo() -> void:
	print("== Mundo 3D: Árbol del Eco -> Aldea Baja -> Cenote Azul -> Camino Secreto -> Estatua ==")
	GameState.new_game()
	await goto(GameState.SCENE_MENU)
	await wait(0.5)
	var btns := _find_buttons(scene())
	(btns["Jugar"] as Button).pressed.emit()
	var ok := await wait_until(func(): return scene() is Mundo3D and not SceneRouter.is_busy(), 40.0)
	check("Jugar carga el mundo 3D", ok)
	if not ok:
		return
	var level := scene() as Mundo3D
	var p := level.player
	var d := level.datos
	check("Mundo 3D construido (geometría, vegetación instanciada, colisiones, luces)", int(level.stats.get("mallas", 0)) > 10 and int(level.stats.get("instancias", 0)) > 5000 and int(level.stats.get("colisiones", 0)) > 50 and int(level.stats.get("luces", 0)) > 40, str(level.stats))
	check("Controles táctiles presentes (joystick, RUN, USAR)", level.hud._touch_controls != null and is_instance_valid(level.hud._touch_controls))
	_off_frames = 0
	_shots_seen = {}
	# ------------------------------------------------ nido
	ok = await wait_until(func(): return level.dialogue.active, 8.0)
	check("Nido: diálogo de despertar", ok)
	_check_shoulder(level, "nido")
	await wait(0.4)
	await shot("M01_nido_interior.png")
	_check_visible(level, "interior del nido")
	await _advance_dialogue(level.dialogue)
	await wait_until(func(): return level.mode == Mundo3D.Mode.EXPLORE, 3.0)
	check("Nido: control restaurado", level.mode == Mundo3D.Mode.EXPLORE and p.input_enabled, "modo=%d entrada=%s dlg=%s %s" % [level.mode, p.input_enabled, level.dialogue.active, str(level.dialogue._lines.map(func(l): return l.get("text", "").left(30)))])
	await _walk_route(level, [d.marker("nido_ventana") + Vector3(-0.3, 0, -0.4)], "hasta la ventana del nido", false, 0.45, 15.0)
	if await _interact_here(level, "ventana", "ventana del nido"):
		await _advance_dialogue(level.dialogue)
	# ------------------------------------------------ rama madre
	ok = await _walk_route(level, [d.marker("nido_puerta"), d.marker("nido_fuera"), Vector3(18.0, 12, -39.9)], "salir por la puerta redonda")
	await wait(0.3)
	_check_shoulder(level, "rama madre")
	await shot("M02_rama_madre.png")
	_check_visible(level, "rama madre")
	await _check_camera_turn(level)
	var max_narrow := 0.0
	var min_spd := 99.0
	var p0 := p.global_position
	var fell := false
	for x in [16.0, 14.0, 12.5, 11.0, 9.8]:
		var t := 0.0
		while t < 12.0 and absf(p.global_position.x - x) > 0.5:
			if level.mode != Mundo3D.Mode.EXPLORE:
				_release_moves()
				await _advance_dialogue(level.dialogue)
				continue
			_steer_towards(p, Vector3(x, 12, -40.2))
			await frames(1)
			t += get_process_delta_time()
			max_narrow = maxf(max_narrow, p.narrow)
			var spd := Vector2(p.velocity.x, p.velocity.z).length()
			if p.narrow > 0.55 and spd > 0.15:
				min_spd = minf(min_spd, spd)
			if p.global_position.y < 10.0:
				fell = true
	_release_moves()
	check("Rama: zona estrecha detectada (equilibrio)", max_narrow > 0.55, "%.2f" % max_narrow)
	check("Rama: más lento haciendo equilibrio", min_spd < 1.6, "%.2f m/s" % min_spd)
	check("Rama: no se cae", not fell and p.global_position.y > 11.0, str(p.global_position))
	# empujar hacia el vacío: no sale de la rama
	_stick(Vector2(0, 1))
	await wait(1.2)
	_release_moves()
	check("Límites: no se puede saltar al vacío desde la rama", d.is_walkable(p.global_position) and p.global_position.y > 11.0)
	await _advance_dialogue(level.dialogue)
	# ------------------------------------------------ anillo y puente de yute
	var ring := []
	for a in range(0, -91, -15):
		ring.append(Vector3(cos(deg_to_rad(a)) * 9.7, 12, -40 - sin(deg_to_rad(a)) * 9.7))
	ok = await _walk_route(level, ring, "anillo alrededor del tronco")
	await shot("M03_anillo.png")
	_check_visible(level, "anillo del tronco")
	ok = await _walk_route(level, [Vector3(-0.3, 12, -26.0), Vector3(-1.0, 11, -19.0)], "puente de yute (primera mitad)")
	_check_shoulder(level, "puente de yute")
	check("Puente de yute: modo equilibrio", p.narrow > 0.5, "%.2f" % p.narrow)
	await shot("M04_puente_yute.png")
	_check_visible(level, "puente de yute")
	await _walk_route(level, [Vector3(-1.7, 11, -12.0), d.marker("mirador_centro")], "puente de yute hasta el mirador", false, 0.7, 60.0, false)
	# ------------------------------------------------ revelación
	ok = await wait_until(func(): return level.director.override_active, 8.0)
	check("Mirador: empieza la revelación (cámara de grúa)", ok and GameState.reveal_seen)
	await wait(0.4)
	ok = await wait_until(func(): return level.dialogue.active, 15.0)
	check("Mirador: la grúa termina con el diálogo", ok)
	await shot("M05_revelacion_aldea.png")
	await _advance_dialogue(level.dialogue)
	check("Mirador: control restaurado y cámara de zona", level.mode == Mundo3D.Mode.EXPLORE and not level.director.override_active)
	# ------------------------------------------------ escalera de la ceiba
	var stairs := []
	for w in d.walk:
		if w["nombre"] == "escalera":
			stairs = w["_pts"]
	var st_route := [d.marker("escalera_arriba")]
	for k in range(0, stairs.size(), 2):
		st_route.append(stairs[k])
	st_route.append(d.marker("escalera_abajo"))
	ok = await _walk_route(level, st_route.slice(0, 9), "escalera de la ceiba (mitad norte)", false, 0.6)
	await shot("M06_escalera.png")
	_check_visible(level, "escalera")
	ok = await _walk_route(level, st_route.slice(9), "escalera de la ceiba hasta el suelo", false, 0.6)
	check("Escalera: llega al suelo de la aldea", p.global_position.y < 1.5, str(p.global_position))
	# ------------------------------------------------ Aldea Baja
	ok = await _walk_route(level, _v3list([[-4.4, -1.6], [-8.0, -8.0], [-10.0, -13.5]]), "camino de las raíces", true)
	if await _interact_here(level, "ninos", "pollitos entre las raíces"):
		await _advance_dialogue(level.dialogue)
	ok = await _walk_route(level, _v3list([[-8.0, -8.0], [-4.4, -1.6], [-2.5, 2.5], [0.0, 6.0], [6.0, 11.0], [10.0, 13.6]]), "bajar a la plaza y al mercado", true)
	check("Aldea: título de zona y objetivo", GameState.village_reached)
	await wait(0.3)
	await shot("M07_mercado.png")
	_check_visible(level, "mercado")
	if await _interact_here(level, "mercader", "Doña Cresta (mercado)"):
		await _advance_dialogue(level.dialogue)
	check("Doña Cresta entrega la ofrenda de maíz", GameState.has_offering)
	ok = await _walk_route(level, _v3list([[4.0, 18.0], [-6.0, 18.4]]), "hasta el Abuelo Espolón", true)
	if await _interact_here(level, "anciano", "Abuelo Espolón"):
		await _advance_dialogue(level.dialogue)
	ok = await _walk_route(level, _v3list([[-7.6, 12.6]]), "hasta la piedra de glifos")
	if await _interact_here(level, "piedra", "piedra de glifos"):
		await _advance_dialogue(level.dialogue)
	ok = await _walk_route(level, _v3list([[-3.0, 10.5], [0.0, 11.0]]), "hasta el pozo tejido")
	if await _interact_here(level, "pozo", "pozo tejido"):
		await wait(0.4)
		await shot("M08_plaza_pozo.png")
		await _advance_dialogue(level.dialogue)
	# movimiento libre en la plaza (cuatro direcciones relativas a la cámara)
	var moves := []
	for dir in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		var q0 := p.global_position
		_stick(dir)
		await wait(0.8)
		_release_moves()
		await wait(0.3)
		moves.append(snappedf(Vector2(p.global_position.x - q0.x, p.global_position.z - q0.z).length(), 0.01))
	check("Plaza: el joystick mueve en las 4 direcciones", moves.all(func(m): return m > 0.5), str(moves))
	await tap("pause")
	await wait(0.3)
	check("Pausa en la exploración 3D", get_tree().paused and level.pause_menu.is_open())
	await shot("M09_pausa_mundo.png")
	await tap("pause")
	await wait(0.3)
	check("Reanudar la exploración", not get_tree().paused and level.mode == Mundo3D.Mode.EXPLORE)
	_check_ui_above_filter(level, "mundo 3D")
	# ------------------------------------------------ camino al Cenote Azul y altar
	ok = await _walk_route(level, _v3list([[6.0, 11.0], [9.0, 11.0], [16.0, 8.0], [22.5, 5.8]]), "camino de piedra al Cenote Azul", true)
	await shot("M10_camino_cenote.png")
	ok = await _walk_route(level, _v3list([[24.6, 7.0], [25.6, 10.5], [27.8, 16.5], [30.3, 21.3]]), "sendero al altar del Guajolote (bajo la raíz)")
	if await _interact_here(level, "altar", "altar al Guajolote"):
		await wait(0.3)
		await shot("M11_altar_cenote.png")
		await _advance_dialogue(level.dialogue)
	ok = await _walk_route(level, _v3list([[27.8, 16.5], [25.6, 10.5], [24.4, 6.5], [32.0, 6.5], [39.0, 8.5], [42.0, 10.2]]), "hasta la entrada del puente de piedra", true)
	await _check_cenote_edge(level)
	ok = await _walk_route(level, _v3list([[42.5, 9.6], [44.0, 12.0], [44.0, 22.0]]), "hasta el puente de piedra", true)
	await _advance_dialogue(level.dialogue)
	await wait(0.3)
	_check_shoulder(level, "puente del cenote")
	await shot("M12_puente_cenote.png")
	_check_visible(level, "puente del cenote")
	# ------------------------------------------------ v13: cascadas, arroyo y vida ambiental
	var cas: Cascadas = level.mundo.cascadas
	check("Cascadas del Cenote Azul: mayor y menor con arroyo, bruma y sonido 3D", cas != null and cas.splash_points.has("mayor") and cas.splash_points.has("menor") and cas.sounds.size() >= 3 and cas.get_node_or_null("Arroyo") != null)
	check("Vida ambiental alrededor del jugador (hojas que caen, motas de luz)", level.vida != null and level.vida._leaves.emitting and level.vida.global_position.distance_to(p.global_position) < 0.5)
	if await _interact_here(level, "cascada", "contemplar la cascada desde el puente"):
		await wait(0.5)
		await shot("M12b_cascada.png")
		await _advance_dialogue(level.dialogue)
		await wait_until(func(): return level.mode == Mundo3D.Mode.EXPLORE, 6.0)
		check("Cascada: la cámara vuelve y el jugador recupera el control", level.mode == Mundo3D.Mode.EXPLORE and p.input_enabled and not level.director.override_active and "cascada" in GameState.village_interactions)
	# ------------------------------------------------ Camino Secreto
	ok = await _walk_route(level, _v3list([[44.0, 30.0], [44.0, 37.5], [44.5, 39.5], [46.5, 41.5]]), "cruzar el puente hasta la orquídea", true)
	await _advance_dialogue(level.dialogue)
	await shot("M13_orquidea.png")
	ok = await _walk_route(level, _v3list([[49.0, 43.0], [50.0, 50.0], [48.5, 58.0], [50.5, 67.0]]), "túnel de lianas (primer tramo)", true)
	await shot("M14_tunel.png")
	_check_visible(level, "túnel")
	ok = await _walk_route(level, _v3list([[53.5, 76.0], [53.5, 84.0], [53.6, 86.8]]), "túnel hasta el Guardián", true)
	# sin entrar: la cortina cierra el paso
	_steer_towards(p, d.marker("guardian") + Vector3(0, 0, 4))
	await wait(1.5)
	_release_moves()
	check("La cortina de lianas cierra el paso antes de la ofrenda", p.global_position.z < d.marker("guardian").z - 0.8 and not level.curtain_open, str(p.global_position))
	await _walk_route(level, [d.marker("guardian_frente")], "ante el Guardián", false, 0.5, 10.0)
	if await _interact_here(level, "guardian", "Guardián del Camino Secreto"):
		await _advance_dialogue(level.dialogue)
		ok = await wait_until(func(): return level.dialogue.active or level.mode == Mundo3D.Mode.EXPLORE, 15.0)
		await wait(0.2)
		await shot("M15_guardian_ofrenda.png")
		await _advance_dialogue(level.dialogue)
	ok = await wait_until(func(): return level.mode == Mundo3D.Mode.EXPLORE, 10.0)
	check("El Guardián acepta la ofrenda y la cortina se abre", GameState.offering_given and level.curtain_open)
	# ------------------------------------------------ claro de la Estatua
	ok = await _walk_route(level, _v3list([[53.8, 92.0], [54.0, 93.5], [55.0, 100.0], [55.0, 104.0]]), "salir del túnel al claro de la Estatua", true)
	await _advance_dialogue(level.dialogue)
	await wait(0.2)
	_check_shoulder(level, "claro de la estatua")
	await shot("M16_claro_estatua.png")
	_check_visible(level, "claro de la estatua")
	ok = false
	for i in 400:
		_steer_towards(p, level.enemy.global_position)
		await frames(1)
		if level.mode != Mundo3D.Mode.EXPLORE:
			ok = true
			break
	_release_moves()
	check("Acercarse al Pollo Negro inicia el encuentro", ok)
	ok = await wait_until(func(): return level.dialogue.active, 10.0)
	check("Diálogo del encuentro", ok)
	await shot("M17_encuentro.png")
	print("  [INFO] planos de cámara vistos: ", _shots_seen.keys())
	print("  [INFO] fotogramas con el personaje fuera de cuadro: ", _off_frames)
	check("Cámara al hombro durante todo el recorrido (sin planos lejanos)", _shots_seen.keys() == ["hombro"], str(_shots_seen.keys()))
	check("El personaje casi nunca queda fuera de cuadro (< 3 % de los fotogramas caminando)", _off_frames < 120, "%d fotogramas" % _off_frames)
	await _advance_dialogue(level.dialogue)
	ok = await wait_until(func(): return scene() is CombatScene and not SceneRouter.is_busy(), 20.0)
	check("Transición al combate", ok)
	if not ok:
		return
	await _combat_flow(true)
	var cs := scene() as CombatScene
	cs.hud.result_choice.emit("continue")
	ok = await wait_until(func(): return scene() is Mundo3D and not SceneRouter.is_busy(), 30.0)
	check("Tras la victoria se vuelve al mundo 3D", ok)
	if not ok:
		return
	level = scene() as Mundo3D
	ok = await wait_until(func(): return level.dialogue.active, 8.0)
	check("Diálogo tras la victoria", ok)
	await _advance_dialogue(level.dialogue)
	await wait(0.4)
	await shot("M18_tras_victoria.png")
	check("Reaparece en el claro con la opción de revancha", level._current_interactable.get("id", "") == "revancha", level._current_interactable.get("id", "-"))
	await goto(GameState.SCENE_MENU)
	check("Volver al menú", scene() is MainMenu)
