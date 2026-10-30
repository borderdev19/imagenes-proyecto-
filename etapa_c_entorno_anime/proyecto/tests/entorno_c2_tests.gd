extends RefCounted
## Pruebas de la revisión C2 del entorno anime: shaders de copa y suelo, árboles por especie, rocas
## facetadas, escena sin objetos de laboratorio, horizonte sin franja azul y luz del ciclo completo.
## Las ejecuta tests/e2e_director.gd en los modos all, unit y anime.

var results: Array = []


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas del entorno anime, revisión C2 ==")
	test_shaders()
	test_arboles()
	test_rocas()
	test_escena(tree)
	return results


func _uniformes(path: String) -> Array:
	var s: Shader = load(path)
	return s.get_shader_uniform_list().map(func(u): return String(u["name"])) if s else []


func test_shaders() -> void:
	var copa := _uniformes(SelvaC2.SH_COPA.resource_path)
	check("C2: shader de copa compila (racimos de hojas con corte alfa)", copa.has("albedo_tex") and copa.has("corte_alfa") and copa.has("mascara_contorno"), str(copa))
	var suelo := _uniformes(SelvaC2.SH_SUELO.resource_path)
	check("C2: shader de suelo compila (zonas de camino, musgo, hojarasca y hierba)", suelo.has("arboles") and suelo.has("c_hojarasca") and suelo.has("camino"), str(suelo))


func test_arboles() -> void:
	var alturas := {}
	for esp in [SelvaC2.Especie.CEIBA, SelvaC2.Especie.REDONDA, SelvaC2.Especie.JOVEN]:
		var a: Dictionary = SelvaC2.arbol(esp, 77)
		var m: ArrayMesh = a["mesh"]
		alturas[esp] = float(a["altura"])
		check("C2: árbol %s con tronco y copa de racimos (2 superficies, %d racimos)" % [["ceiba", "redonda", "joven"][esp], int(a["racimos"])],
			m.get_surface_count() == 2 and int(a["racimos"]) >= 5)
	check("C2: especies con alturas distintas (ceiba > joven y redonda)", alturas[SelvaC2.Especie.CEIBA] > alturas[SelvaC2.Especie.JOVEN] + 4.0
		and alturas[SelvaC2.Especie.CEIBA] > alturas[SelvaC2.Especie.REDONDA] + 4.0, str(alturas))
	var a1: Dictionary = SelvaC2.arbol(SelvaC2.Especie.REDONDA, 1)
	var a2: Dictionary = SelvaC2.arbol(SelvaC2.Especie.REDONDA, 2)
	check("C2: dos semillas dan árboles distintos (no son clones)", (a1["mesh"] as ArrayMesh).get_aabb() != (a2["mesh"] as ArrayMesh).get_aabb())


func test_rocas() -> void:
	var r := SelvaC2.roca(9, Vector3(1.2, 0.8, 1.0), 5)
	var arr: Array = r.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var c := r.get_aabb().get_center()
	var fuera := 0
	for i in v.size():
		if n[i].dot(v[i] - c) > 0.0:
			fuera += 1
	check("C2: roca con normales hacia fuera", float(fuera) / float(maxi(v.size(), 1)) > 0.9, "%d/%d" % [fuera, v.size()])
	# facetas: muchas normales casi idénticas (planos), no una esfera lisa
	var planos := 0
	for i in range(0, n.size() - 3, 3):
		if n[i].dot(n[i + 1]) > 0.97 and n[i].dot(n[i + 2]) > 0.97:
			planos += 1
	check("C2: roca facetada (caras planas, no un guijarro liso)", planos > n.size() / 3 / 4, "%d caras planas" % planos)
	check("C2: base de la roca hundida en el suelo", r.get_aabb().position.y < 0.0 and r.get_aabb().position.y > -0.5, "min y %.2f" % r.get_aabb().position.y)


func test_escena(tree: SceneTree) -> void:
	var lab: PruebaEntornoC2 = (load(PruebaEntornoC2.ESCENA_C2) as PackedScene).instantiate()
	tree.root.add_child(lab)
	check("C2: escena sin esferas ni objetos de laboratorio",
		lab.find_children("Esfera*", "", true, false).is_empty() and lab.find_children("Tablon*", "", true, false).is_empty() and lab.negro == null)
	check("C2: bosque con especies variadas", int(lab.especies["ceiba"]) >= 3 and int(lab.especies["redonda"]) >= 15 and int(lab.especies["joven"]) >= 8
		and int(lab.especies["palma"]) >= 3, str(lab.especies))
	check("C2: anillo lejano de bosque que cierra el horizonte", int(lab.especies["lejano"]) >= 100, str(lab.especies["lejano"]))
	lab.set_hora(13.0)
	var sky: ProceduralSkyMaterial = lab.env_anime.sky.sky_material
	var hz := sky.sky_horizon_color
	check("C2: horizonte sin franja azul (el horizonte del cielo tiende a la bruma)", hz.b - hz.g < 0.15 and hz.s < 0.4, str(hz))
	check("C2: el suelo del cielo y la niebla son el mismo color", sky.ground_horizon_color.is_equal_approx(lab.env_anime.fog_light_color))
	var cenit := sky.sky_top_color
	check("C2: cielo de mediodía azul con saturación contenida", cenit.b > cenit.g and cenit.s > 0.5 and cenit.s < 0.85, str(cenit))
	var e_dia := lab.sun.light_energy
	lab.set_hora(18.2)
	var c_tarde := lab.sun.light_color
	check("C2: atardecer cálido sin teñir todo de rosa (verde del sol >= 0.7)", c_tarde.r > c_tarde.b and c_tarde.g >= 0.7, str(c_tarde))
	lab.set_hora(0.0)
	check("C2: noche legible (sol lunar y ambiente por encima de 0.3, más oscura que el día)",
		lab.sun.light_energy > 0.3 and lab.env_anime.ambient_light_energy > 0.3 and lab.sun.light_energy < e_dia)
	lab.aplicar_estilo(Ajustes.ESTILO_PICTORICO)
	var arbol_anime: Node3D = lab.find_children("Arbol_*", "MeshInstance3D", true, false)[0]
	var arbol_v13: Node3D = lab.find_children("v13_*", "MeshInstance3D", true, false)[0]
	check("C2: el estilo v13 muestra sus árboles y rocas originales y oculta los nuevos", not arbol_anime.visible and arbol_v13.visible and lab.we.environment == lab.env_v13)
	lab.aplicar_estilo(Ajustes.ESTILO_ANIME)
	check("C2: el estilo anime vuelve a mostrar los nuevos", arbol_anime.visible and not arbol_v13.visible and lab.we.environment == lab.env_anime)
	lab.queue_free()
