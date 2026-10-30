extends RefCounted
## Pruebas del entorno anime (Etapa C): shader del suelo, mallas procedurales (suelo, copas, rocas),
## escena de prueba del entorno, cielo por hora y que el estilo v13 siga con sus recursos originales.
## Las ejecuta tests/e2e_director.gd en los modos all, unit y anime.

var results: Array = []


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas del entorno anime (Etapa C) ==")
	test_shader()
	test_mallas()
	test_escena(tree)
	return results


func test_shader() -> void:
	var s: Shader = load("res://assets/materials/anime/anime_terreno.gdshader")
	var nombres: Array = s.get_shader_uniform_list().map(func(u): return String(u["name"])) if s else []
	check("Shader anime del suelo compila y expone sus parámetros", s != null and nombres.has("saturacion") and nombres.has("detalle") and nombres.has("mascara_contorno") and nombres.has("bandas"),
		str(nombres))


func test_mallas() -> void:
	var suelo := EntornoSelva.malla_terreno(40.0, 12, 3)
	var arr: Array = suelo.surface_get_arrays(0)
	var normales: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var colores: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var arriba := 0
	for n in normales:
		if n.y > 0.5:
			arriba += 1
	check("Suelo: malla con color por vértice y normales hacia arriba", suelo.get_surface_count() == 1 and colores.size() == normales.size() and normales.size() > 0
		and float(arriba) / float(normales.size()) > 0.95, "%d/%d hacia arriba" % [arriba, normales.size()])
	var copa := EntornoSelva.copa(5, 3.0)
	check("Masa de copa: normales hacia fuera (se ve la cara exterior con cull_back)", _hacia_fuera(copa) > 0.95, "%.3f" % _hacia_fuera(copa))
	var roca := EntornoSelva.roca(9, 1.0)
	check("Roca estilizada: normales hacia fuera y base apoyada en el suelo",
		_hacia_fuera(roca) > 0.95 and roca.get_aabb().position.y > -0.2, "min y %.3f" % roca.get_aabb().position.y)


## Fracción de normales que apuntan desde el centro de la malla hacia fuera.
func _hacia_fuera(m: ArrayMesh) -> float:
	var arr: Array = m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var c := m.get_aabb().get_center()
	var buenas := 0
	for i in v.size():
		if n[i].dot(v[i] - c) > 0.0:
			buenas += 1
	return float(buenas) / float(maxi(v.size(), 1))


func test_escena(tree: SceneTree) -> void:
	var lab: PruebaEntorno = (load(PruebaEntorno.ESCENA_ENTORNO) as PackedScene).instantiate()
	tree.root.add_child(lab)
	var suelo := lab.find_children("Suelo_Selva", "MeshInstance3D", true, false)
	check("Escena del entorno: suelo de selva montado", suelo.size() == 1)
	check("Escena del entorno: bosque de fondo con árboles repartidos", int(lab.stats.get("arboles_extra", 0)) >= 10, "%d" % int(lab.stats.get("arboles_extra", 0)))
	check("Escena del entorno: el estilo anime tiene cielo propio y el v13 conserva el del ciclo",
		lab.env_anime.sky != null and lab.env_anime.sky.sky_material is ProceduralSkyMaterial and not (lab.env_v13.sky.sky_material is ProceduralSkyMaterial))
	lab.set_hora(13.0)
	var cenit: Color = lab._sky_mat.sky_top_color
	check("Cielo anime al mediodía: azul saturado, no blanco lavado", cenit.b > cenit.r + 0.3 and cenit.b > cenit.g and cenit.b > 0.8, str(cenit))
	lab.set_hora(21.0)
	check("Cielo anime de noche: más oscuro que al mediodía", lab._sky_mat.sky_top_color.v < cenit.v)
	lab.aplicar_estilo(Ajustes.ESTILO_PICTORICO)
	check("Entorno: el estilo v13 no usa las piezas nuevas del entorno", lab.we.environment == lab.env_v13 and not (lab.env_v13.sky.sky_material is ProceduralSkyMaterial))
	lab.queue_free()
