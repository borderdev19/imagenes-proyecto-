extends RefCounted
## Pruebas de la revisión C3 del entorno anime: especies nuevas, shaders de suelo y luciérnagas,
## primer plano despejado, raíces que no bloquean el camino, noche legible sin subir la exposición,
## MultiMesh (menos nodos de dibujo que la C2) y personaje en escena.
## Las ejecuta tests/e2e_director.gd en los modos all, unit y anime.

var results: Array = []


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas del entorno anime, revisión C3 ==")
	test_shaders()
	test_especies()
	test_noche_formula()
	test_escena(tree)
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


func test_escena(tree: SceneTree) -> void:
	var c3: PruebaEntornoC3 = (load(PruebaEntornoC3.ESCENA_C3) as PackedScene).instantiate()
	tree.root.add_child(c3)
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
	c3.set_hora(13.0)
	check("C3: de día las luces de noche se apagan", not c3._luces_noche[0].visible)
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
	c3.queue_free()
