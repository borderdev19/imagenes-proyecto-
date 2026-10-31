extends RefCounted
## Pruebas de la revisión C3 del entorno anime: especies nuevas, shaders de suelo y luciérnagas,
## primer plano despejado, raíces que no bloquean el camino, noche legible sin subir la exposición,
## MultiMesh (menos nodos de dibujo que la C2) y personaje en escena. Validación en movimiento: el
## Pollo Amarillo jugable recorre el camino caminando y corriendo con las entradas del jugador, gira,
## choca con troncos y rocas sin atravesarlos y la cámara al hombro gira sin meterse en troncos ni copas.
## Las ejecuta tests/e2e_director.gd en los modos all, unit, anime y c3.

var results: Array = []


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas del entorno anime, revisión C3 ==")
	test_shaders()
	test_especies()
	test_noche_formula()
	var c3: PruebaEntornoC3 = (load(PruebaEntornoC3.ESCENA_C3) as PackedScene).instantiate()
	tree.root.add_child(c3)
	test_escena(tree, c3)
	await test_recorrido(tree, c3)
	c3.queue_free()
	return results


func _uniformes(s: Shader) -> Array:
	return s.get_shader_uniform_list().map(func(u): return String(u["name"])) if s else []


func test_shaders() -> void:
	var suelo := _uniformes(SelvaC3.SH_SUELO_C3)
	check("C3: shader de suelo compila (rocas, luna, roderas)", suelo.has("rocas") and suelo.has("luna") and suelo.has("c_piedra") and suelo.has("arboles"), str(suelo.size()))
	var luz := _uniformes(SelvaC3.SH_LUCIERNAGA)
	check("C3: shader de luciérnagas compila", luz.has("intensidad") and luz.has("color_luz"), str(luz))


func test_especies() -> void:
	var mon := SelvaC3.arbol(SelvaC3.Especie.MONUMENTAL, 3)
	check("C3: árbol monumental de más de 25 m con raíces expuestas", float(mon["altura"]) > 25.0 and int(mon["raices"]) >= 8 and (mon["mesh"] as ArrayMesh).get_surface_count() == 2,
		"altura %.1f, raíces %d" % [float(mon["altura"]), int(mon["raices"])])
	var pis := SelvaC3.arbol(SelvaC3.Especie.PISOS, 3)
	var cec := SelvaC3.arbol(SelvaC3.Especie.CECROPIA, 3)
	var inc := SelvaC3.arbol(SelvaC3.Especie.INCLINADO, 3)
	check("C3: especie en pisos con copa ancha (silueta de pagoda)", float(pis["radio_copa"]) > 4.0 and int(pis["racimos"]) >= 20, "radio %.1f, racimos %d" % [float(pis["radio_copa"]), int(pis["racimos"])])
	check("C3: cecropia con pocas rosetas en candelabro", int(cec["racimos"]) <= 6 and float(cec["altura"]) > 9.0, "racimos %d" % int(cec["racimos"]))
	var aabb := (inc["mesh"] as ArrayMesh).get_aabb()
	check("C3: árbol inclinado: la copa queda desplazada del pie", aabb.get_center().x > 2.0, "centro x %.2f" % aabb.get_center().x)
	var alturas := [float(mon["altura"]), float(pis["altura"]), float(cec["altura"]), float(SelvaC3.arbol(SelvaC2.Especie.REDONDA, 3)["altura"])]
	check("C3: las especies tienen alturas claramente distintas", alturas.max() - alturas.min() > 15.0, str(alturas))


func test_noche_formula() -> void:
	check("C3: factor de noche 0 de día, 1 de noche, rampa al anochecer",
		PruebaEntornoC3.factor_noche(13.0) == 0.0 and PruebaEntornoC3.factor_noche(0.0) == 1.0 and PruebaEntornoC3.factor_noche(21.0) == 1.0
		and PruebaEntornoC3.factor_noche(19.7) > 0.0 and PruebaEntornoC3.factor_noche(19.7) < 1.0)


func _nodos_dibujo(n: Node) -> int:
	var c := 0
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).visible and (g is MeshInstance3D or g is MultiMeshInstance3D):
			c += 1
	return c


func test_escena(tree: SceneTree, c3: PruebaEntornoC3) -> void:
	check("C3: la escena carga sin objetos de laboratorio", c3.find_children("Esfera*", "", true, false).is_empty() and c3.negro == null)
	var esp: Dictionary = c3.especies_c3
	var n_esp := 0
	for k in ["ceiba", "redonda", "joven", "monumental", "pisos", "cecropia", "inclinado", "palma"]:
		if int(esp.get(k, 0)) > 0:
			n_esp += 1
	check("C3: 8 tipos de árbol en el bosque cercano (7 especies y palmas)", n_esp == 8, str(esp))
	check("C3: árboles en MultiMesh (más de 300 instancias en pocas variantes)", c3.mm_arboles > 300 and int(c3.stats["variantes_arbol"]) <= 30,
		"%d instancias, %d variantes" % [c3.mm_arboles, int(c3.stats["variantes_arbol"])])
	# primer plano: ninguna planta grande ni árbol cercano delante de las cámaras ni en el camino
	var malas := 0
	var total := 0
	# (las transformaciones se leen de la escena: el renderizador headless no guarda las de la MultiMesh)
	for nom in c3._por_planta:
		for t in c3._por_planta[nom]:
			var p: Vector3 = (t as Transform3D).origin
			total += 1
			if (not String(nom).begins_with("Palma") and SelvaC2.distancia_camino(p) < 2.9) or c3._en_zona_camara(p):
				malas += 1
	check("C3: plantas grandes fuera del camino y del primer plano de las cámaras", total > 50 and malas == 0, "%d de %d mal colocadas" % [malas, total])
	# raíces: no cruzan el centro del camino
	var raices: MeshInstance3D = c3.find_child("Raices_C3", true, false)
	var en_camino := 0
	if raices:
		for v in (raices.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if SelvaC2.distancia_camino(v) < 0.9:
				en_camino += 1
	check("C3: raíces expuestas que no bloquean el centro del camino", raices != null and int(c3.stats["raices_c3"]) >= 20 and en_camino == 0,
		"%d raíces, %d vértices en el centro" % [int(c3.stats.get("raices_c3", 0)), en_camino])
	check("C3: rocas en grupos con piedrecillas", int(c3.stats["rocas_c3"]) >= 40, str(c3.stats["rocas_c3"]))
	# noche: más legible por luz selectiva, sin subir la exposición
	c3.set_hora(13.0)
	var expo_dia: float = c3.env_anime.tonemap_exposure
	var luc_dia: float = c3._luciernagas_mat.get_shader_parameter("intensidad")
	c3.set_hora(21.0)
	check("C3: de noche se encienden luciérnagas y luces suaves; de día no", luc_dia == 0.0 and float(c3._luciernagas_mat.get_shader_parameter("intensidad")) > 1.0
		and c3._luces_noche.size() == 3 and c3._luces_noche[0].visible)
	check("C3: noche legible (luna 0.72, ambiente 0.62) con la misma exposición que de día",
		is_equal_approx(c3.sun.light_energy, 0.72) and is_equal_approx(c3.env_anime.ambient_light_energy, 0.62) and c3.env_anime.tonemap_exposure == expo_dia)
	check("C3: la bruma nocturna es más clara que el cielo del cénit (siluetas separadas)",
		c3.env_anime.fog_light_color.v > (c3.env_anime.sky.sky_material as ProceduralSkyMaterial).sky_top_color.v)
	c3.set_plano("escala")
	check("C3: de noche un relleno frío suave acompaña al personaje (sin sombras)", c3.luz_personaje.visible and not c3.luz_personaje.shadow_enabled
		and c3.luz_personaje.global_position.distance_to(c3.amarillo.global_position) < 3.0 and c3.luz_personaje.light_energy < 1.0)
	c3.set_plano("general")
	c3.set_hora(13.0)
	check("C3: de día las luces de noche se apagan", not c3._luces_noche[0].visible and not c3.luz_personaje.visible)
	# personaje y encuadre de escala
	c3.set_plano("escala")
	check("C3: el personaje jugable está en el camino y visible en el plano de escala",
		c3.amarillo != null and c3.amarillo.visible and SelvaC2.distancia_camino(c3.amarillo.global_position) < 0.5 and c3.amarillo.has_method("play"))
	c3.set_plano("general")
	check("C3: el personaje se oculta en los demás encuadres", not c3.amarillo.visible)
	# menos nodos de dibujo que la C2
	var c2: PruebaEntornoC2 = (load(PruebaEntornoC2.ESCENA_C2) as PackedScene).instantiate()
	tree.root.add_child(c2)
	var n2 := _nodos_dibujo(c2)
	var n3 := _nodos_dibujo(c3)
	# MultiMesh por variante y sector de 60 m: menos nodos que la C2 aunque haya más vegetación
	check("C3: menos nodos de dibujo que la C2 (MultiMesh por variante y sector)", n3 < n2 * 0.75, "C2 %d, C3 %d" % [n2, n3])
	c2.queue_free()


# ------------------------------------------------------------------ recorrido con el personaje
var _hojas := {}          # malla -> [caras de las hojas, AABB]
var _muestras := {}


## Caras de las hojas de una malla (superficie de racimos u hojas) y su caja, para ver si tapan la cámara.
func _hojas_de(mesh: Mesh, sf: int) -> Array:
	if not _hojas.has(mesh):
		var a := mesh.surface_get_arrays(sf)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var caras := v
		var idx = a[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and not idx.is_empty():
			caras = PackedVector3Array()
			caras.resize(idx.size())
			for i in idx.size():
				caras[i] = v[idx[i]]
		var caja := AABB(caras[0], Vector3.ZERO)
		for q in caras:
			caja = caja.expand(q)
		_hojas[mesh] = [caras, caja]
	return _hojas[mesh]


## Copas, palmas y plantas grandes cuyas hojas cortan el segmento cámara-cabeza.
func _hojas_tapan(c3: PruebaEntornoC3, desde: Vector3, hasta: Vector3) -> String:
	var lista := []
	for clave in c3._tipos_arbol:
		var t: Dictionary = c3._tipos_arbol[clave]
		for tr in t["ts"]:
			lista.append([t["mesh"], 1, tr, String(clave)])
	var lib := c3._biblioteca()
	for nom in c3._por_planta:
		if lib.has(nom):
			for tr in c3._por_planta[nom]:
				lista.append([lib[nom], 0, tr, String(nom)])
	for e in lista:
		var tr: Transform3D = e[2]
		if Vector2(tr.origin.x - hasta.x, tr.origin.z - hasta.z).length() > 16.0:
			continue
		var h := _hojas_de(e[0], e[1])
		var inv := tr.affine_inverse()
		var a := inv * desde
		var b := inv * hasta
		var caja: AABB = h[1]
		if not caja.intersects_segment(a, b) and not caja.has_point(a):
			continue
		var caras: PackedVector3Array = h[0]
		for i in range(0, caras.size(), 3):
			if Geometry3D.segment_intersects_triangle(a, b, caras[i], caras[i + 1], caras[i + 2]) != null:
				return String(e[3])
	return ""


func _dentro(c3: PruebaEntornoC3, pos: Vector3) -> bool:
	# cápsula algo menor que la del personaje, por encima de la altura de escalón (raíces bajas)
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.24
	cap.height = 0.95
	q.shape = cap
	q.transform = Transform3D(Basis(), pos + Vector3(0, 0.42 + 0.475, 0))
	q.exclude = [c3.colision_suelo.get_rid(), c3.jugador.get_rid()]
	return not c3.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _forma_nombre(c3: PruebaEntornoC3, hit: Dictionary) -> String:
	var o: Object = hit.get("collider")
	if o is StaticBody3D:
		var cs := (o as StaticBody3D).shape_owner_get_owner((o as StaticBody3D).shape_find_owner(int(hit.get("shape", 0))))
		if cs is CollisionShape3D:
			return "%s %s" % [(cs as CollisionShape3D).shape.get_class(), (cs as CollisionShape3D).position]
	return str(o)


## Tronco, rama, raíz, roca o tallo entre la cabeza del personaje y la cámara.
func _vista_bloqueada(c3: PruebaEntornoC3) -> String:
	var cp := c3.cam.global_position
	var r := PhysicsRayQueryParameters3D.create(c3.jugador.global_position + Vector3(0, 1.1, 0), cp)
	r.exclude = [c3.jugador.get_rid()]
	r.hit_back_faces = true
	var hit := c3.get_world_3d().direct_space_state.intersect_ray(r)
	if hit.is_empty():
		return ""
	return "%s a %.2f m de la cámara" % [_forma_nombre(c3, hit), (hit["position"] as Vector3).distance_to(cp)]


func _camara_mal(c3: PruebaEntornoC3) -> String:
	var cp := c3.cam.global_position
	if cp.y < SelvaC2.altura_suelo(cp.x, cp.z, PruebaEntornoC2.SEMILLA_C2) + 0.25:
		return "bajo el suelo"
	var q := PhysicsPointQueryParameters3D.new()
	q.position = cp
	q.exclude = [c3.colision_suelo.get_rid()]
	var espacio := c3.get_world_3d().direct_space_state
	if not espacio.intersect_point(q, 1).is_empty():
		return "dentro de un obstáculo"
	return ""


## Sigue al personaje mientras el piloto lo conduce y anota lo que pasa.
func _seguir(tree: SceneTree, c3: PruebaEntornoC3, m: Dictionary, limite: float) -> bool:
	var t := 0.0
	var quieto := 0.0
	var f := 0
	while c3.pilotando() and t < limite:
		await tree.physics_frame
		var dt := 1.0 / 60.0
		t += dt
		f += 1
		var j := c3.jugador
		var v := Vector2(j.velocity.x, j.velocity.z).length()
		m["vmax"] = maxf(float(m.get("vmax", 0.0)), v)
		quieto = quieto + dt if v < 0.15 and t > 1.0 else 0.0
		m["atasco"] = maxf(float(m.get("atasco", 0.0)), quieto)
		if m.has("rastro") and j.global_position.distance_to((m["rastro"] as Array).back()) > 0.8:
			(m["rastro"] as Array).append(j.global_position)
		if _dentro(c3, j.global_position):
			m["dentro"] = int(m.get("dentro", 0)) + 1
			m["donde"] = j.global_position
		if f % 6 == 0:
			m["camaras"] = int(m.get("camaras", 0)) + 1
			var mal := _camara_mal(c3)
			if mal != "":
				m["cam_mal"] = int(m.get("cam_mal", 0)) + 1
				m["cam_mal_que"] = mal
			var cabeza := j.global_position + Vector3(0, 1.1, 0)
			if c3.cam.global_position.distance_to(cabeza) < 1.0:
				m["cerca"] = int(m.get("cerca", 0)) + 1
			var tapa := _vista_bloqueada(c3)
			if tapa == "":
				tapa = _hojas_tapan(c3, c3.cam.global_position, cabeza)
			if tapa != "":
				m["tapada"] = int(m.get("tapada", 0)) + 1
				m["tapa_que"] = tapa
	return not c3.pilotando()


func test_recorrido(tree: SceneTree, c3: PruebaEntornoC3) -> void:
	print("  · recorrido con el personaje (caminar, correr, girar, cámara)")
	c3.set_hora(13.0)
	c3.jugar(true)
	var j := c3.jugador
	var rescates := [0]
	j.rescued.connect(func(): rescates[0] += 1)
	for i in 20:
		await tree.physics_frame
	check("C3 recorrido: el Pollo Amarillo jugable (controlador y cámara al hombro del juego) aparece en el camino",
		j.is_on_floor() and j.visible and not c3.amarillo.visible and c3.director.current == "hombro" and j.walk_check.is_valid(),
		"suelo %s, %d formas de colisión (%d árboles, %d rocas)" % [j.is_on_floor(), int(c3.stats["formas_colision"]), int(c3.stats["colision_arboles"]), int(c3.stats["colision_rocas"])])
	# caminar y correr por todo el camino
	var cam_m := {}
	var mc := {}
	c3.pilotar(PruebaEntornoC3.puntos_camino(PruebaEntornoC3.INICIO_Z, -22.0))
	var ok1 := await _seguir(tree, c3, mc, 40.0)
	var mr := {}
	c3.pilotar(PruebaEntornoC3.puntos_camino(-22.0, -86.0), true)
	var ok2 := await _seguir(tree, c3, mr, 40.0)
	for m in [mc, mr]:
		for k in ["dentro", "camaras", "cam_mal", "cerca", "tapada"]:
			cam_m[k] = int(cam_m.get(k, 0)) + int(m.get(k, 0))
		for k in ["donde", "cam_mal_que", "tapa_que"]:
			if m.has(k):
				cam_m[k] = m[k]
	check("C3 recorrido: recorre el camino entero (96 m) caminando y corriendo, sin atascos ni rescates",
		ok1 and ok2 and rescates[0] == 0 and float(mc.get("atasco", 0.0)) < 0.5 and float(mr.get("atasco", 0.0)) < 0.5,
		"caminar %s, correr %s, rescates %d, atasco %.2f s / %.2f s, llega a z %.1f" % [ok1, ok2, rescates[0], float(mc.get("atasco", 0.0)), float(mr.get("atasco", 0.0)), j.global_position.z])
	check("C3 recorrido: camina a la velocidad del juego y corre con la tecla de correr",
		float(mc["vmax"]) > 2.0 and float(mc["vmax"]) < 2.6 and float(mr["vmax"]) > 4.0, "caminar %.2f m/s, correr %.2f m/s" % [float(mc["vmax"]), float(mr["vmax"])])
	# media vuelta
	var p := j.global_position
	var y0 := j.facing_yaw
	c3.pilotar([p + Vector3(0, 0, 3.0)])
	for i in 60:
		await tree.physics_frame
	var giro := absf(wrapf(j.facing_yaw - y0, -PI, PI))
	await _seguir(tree, c3, {}, 6.0)
	check("C3 recorrido: gira el cuerpo antes de avanzar (media vuelta en menos de 1 s)", giro > PI * 0.85, "giro %.0f°" % rad_to_deg(giro))
	# choques: contra el grupo de rocas, el tronco inclinado y el árbol monumental
	var choques := []
	var dentro := 0
	# [nombre, centro, distancia mínima al centro: radio del obstáculo menos su irregularidad]
	var obj := [["rocas", Vector3(SelvaC2.camino_x(-12.0) - 4.4, 0, -12.3), 1.0], ["tronco inclinado", Vector3(SelvaC2.camino_x(-12.0) - 4.6, 0, -12.0), 0.6],
		["monumental", c3._monumental_pos, 1.2], ["tronco caído", Vector3(SelvaC2.camino_x(-3.5) - 4.2, 0, -3.5), 0.3]]
	for o in obj:
		var centro: Vector3 = o[1]
		var desde := Vector3(SelvaC2.camino_x(centro.z), 0, centro.z)
		j.place(desde + Vector3(0, SelvaC2.altura_suelo(desde.x, desde.z, PruebaEntornoC2.SEMILLA_C2) + 0.05, 0), 0.0)
		for i in 10:
			await tree.physics_frame
		var m := {}
		c3.pilotar([centro])
		await _seguir(tree, c3, m, 5.0)
		c3.pilotar([])
		c3._soltar()
		var d := Vector2(j.global_position.x - centro.x, j.global_position.z - centro.z).length()
		choques.append("%s %.2f m (altura %.2f)%s" % [o[0], d, j.global_position.y, (" (dentro %d)" % int(m["dentro"])) if m.has("dentro") else ""])
		if d < float(o[2]) or int(m.get("dentro", 0)) > 0:
			dentro += 1
	check("C3 recorrido: al caminar contra rocas, troncos y el árbol monumental se detiene sin atravesarlos",
		dentro == 0 and int(cam_m.get("dentro", 0)) == 0, ", ".join(choques) + (" · dentro en el camino: %s" % cam_m.get("donde") if cam_m.has("donde") else ""))
	# cámara durante el recorrido
	var n_cam := maxi(int(cam_m.get("camaras", 0)), 1)
	check("C3 recorrido: la cámara al hombro no entra en troncos, rocas ni el suelo",
		int(cam_m.get("cam_mal", 0)) == 0, "%d de %d muestras %s" % [int(cam_m.get("cam_mal", 0)), n_cam, cam_m.get("cam_mal_que", "")])
	# el detector de hojas funciona: un segmento vertical por dentro de la copa del monumental la corta
	var mp := c3._monumental_pos
	var detector := _hojas_tapan(c3, mp + Vector3(0, 2.0, 0), mp + Vector3(0.5, 45.0, 0.5)) != ""
	check("C3 recorrido: copas, ramas, troncos y plantas no tapan al personaje (menos del 3 % de las muestras)",
		detector and float(cam_m.get("tapada", 0)) / n_cam < 0.03, "%d de %d muestras tapadas (último: %s) · detector de hojas %s" % [int(cam_m.get("tapada", 0)), n_cam, cam_m.get("tapa_que", "-"), "comprobado" if detector else "SIN COMPROBAR"])
	check("C3 recorrido: la cámara no se pega al personaje (más de 1 m de la cabeza)",
		float(cam_m.get("cerca", 0)) / n_cam < 0.05, "%d de %d muestras" % [int(cam_m.get("cerca", 0)), n_cam])
	# fuera del camino: 24 paseos al bosque cercano y vuelta al camino (raíces, rocas, troncos, plantas)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var mb := {}
	var atrapado := 0
	var resc0: int = rescates[0]
	var notas := []
	for k in 24:
		var z := rng.randf_range(-70.0, 6.0)
		var x0 := SelvaC2.camino_x(z)
		j.place(Vector3(x0, SelvaC2.altura_suelo(x0, z, PruebaEntornoC2.SEMILLA_C2) + 0.05, z), rng.randf() * TAU)
		for i in 8:
			await tree.physics_frame
		var lado := -1.0 if k % 2 == 0 else 1.0
		var meta := Vector3(x0 + lado * rng.randf_range(4.0, 12.0), 0, z + rng.randf_range(-4.0, 4.0))
		c3.pilotar([meta])
		var rastro := [j.global_position]
		mb["rastro"] = rastro
		await _seguir(tree, c3, mb, 7.0)
		mb.erase("rastro")
		# vuelve por donde fue (el piloto va en línea recta: así no se confunde un rodeo con quedar atrapado)
		rastro.reverse()
		c3.pilotar(rastro)
		var volvio := await _seguir(tree, c3, mb, 12.0)
		if not volvio:
			atrapado += 1
			notas.append("(%.1f, %.1f)" % [j.global_position.x, j.global_position.z])
	c3._soltar()
	var n_b := maxi(int(mb.get("camaras", 0)), 1)
	check("C3 recorrido: 24 paseos fuera del camino entre raíces, rocas y troncos sin atravesarlos, sin quedar atrapado y sin rescates",
		int(mb.get("dentro", 0)) == 0 and atrapado == 0 and rescates[0] == resc0,
		"dentro %d fotogramas, atrapado %d %s, rescates %d" % [int(mb.get("dentro", 0)), atrapado, " ".join(notas), rescates[0] - resc0])
	check("C3 recorrido: fuera del camino la cámara tampoco entra en obstáculos y la vista queda tapada menos del 10 % de las muestras",
		int(mb.get("cam_mal", 0)) == 0 and float(mb.get("tapada", 0)) / n_b < 0.1,
		"cámara mal %d (%s), tapada %d de %d (último: %s)" % [int(mb.get("cam_mal", 0)), mb.get("cam_mal_que", ""), int(mb.get("tapada", 0)), n_b, mb.get("tapa_que", "-")])
	# giro manual de la cámara con el personaje quieto, en tres sitios del camino
	var giros := []
	var mal := 0
	for z in [6.0, -20.0, -40.0]:
		var x := SelvaC2.camino_x(z)
		j.place(Vector3(x, SelvaC2.altura_suelo(x, z, PruebaEntornoC2.SEMILLA_C2) + 0.05, z), PI)
		for i in 15:
			await tree.physics_frame
		var yaw0 := c3.director.yaw
		var pitch0 := c3.director.pitch
		for accion in ["cam_left", "cam_up", "cam_right", "cam_down"]:
			var t := 0.0
			while t < (2.0 if accion in ["cam_left", "cam_right"] else 0.6):
				Input.action_press(accion)
				await tree.physics_frame
				t += 1.0 / 60.0
				if _camara_mal(c3) != "":
					mal += 1
			Input.action_release(accion)
			if accion == "cam_left":
				giros.append("%.0f°" % rad_to_deg(c3.director.yaw - yaw0))
			if accion == "cam_up":
				giros.append("inclina %.0f°" % rad_to_deg(c3.director.pitch - pitch0))
	check("C3 recorrido: la cámara gira a mano alrededor del personaje sin meterse en obstáculos", mal == 0 and giros.size() == 6, ", ".join(giros) + " · %d fotogramas mal" % mal)
	# escala del personaje
	var cap := (j.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	var mon := SelvaC3.arbol(SelvaC3.Especie.MONUMENTAL, 3)
	check("C3 recorrido: escala coherente (personaje de 1,45 m, camino de unos 2,6 m, monumental más de 15 veces más alto)",
		is_equal_approx(cap.height, 1.45) and float(mon["altura"]) / cap.height > 15.0 and SelvaC2.CAMINO.w / (cap.radius * 2.0) > 3.0,
		"monumental %.1f m" % float(mon["altura"]))
	c3.jugar(false)
	check("C3 recorrido: al salir del recorrido vuelve el encuadre general y se oculta el personaje", not j.visible and c3.plano == "general")
