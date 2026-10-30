class_name PruebaEntornoC3
extends PruebaEntornoC2
## Etapa C del estilo anime, revisión C3: la selva de la C2 refinada, en una escena propia. La escena
## C2 no cambia y sirve de comparación (mismos encuadres y mismas horas).
##
## Cambios frente a la C2:
## - 7 especies de árbol (las 3 de la C2 y monumental, en pisos, cecropia e inclinado), con escala no
##   uniforme y ramitas que unen ramas y racimos. Un árbol monumental al fondo del camino como punto
##   focal y dos árboles inclinados que enmarcan el recorrido.
## - Árboles, plantas grandes y rocas en MultiMesh por variante (menos llamadas de dibujo que la C2).
## - Primer plano más limpio: plantas grandes a 3 m o más del eje del camino, escalas más contenidas y
##   zonas libres delante de cada cámara de encuadre.
## - Raíces expuestas que serpentean hacia el camino, rocas hundidas con piedrecillas, y suelo con tierra
##   húmeda y musgo al pie de las rocas, roderas y piedrecillas en el camino.
## - Noche: luna más presente y fría, bruma azul más clara que las siluetas, ambiente verde azulado,
##   borde de luz de luna en las copas, camino algo más legible y luciérnagas con tres luces suaves.
##   La exposición general no se sube.
##
## Teclas: 1-8 encuadre · H hora · O contornos · Esc menú (el estilo es siempre anime: la comparación
## con la C2 se hace con su propia escena).
## Capturas: godot --path . res://scenes/pruebas/PruebaEntornoAnimeC3.tscn -- --capturas=/ruta

const ESCENA_C3 := "res://scenes/pruebas/PruebaEntornoAnimeC3.tscn"
const SEMILLA_C3 := 5151
const Esp2 := SelvaC2.Especie
const Esp3 := SelvaC3.Especie
## Árbol monumental: punto focal al fondo del camino.
const MONUMENTAL_Z := -46.0

var especies_c3 := {}
var _tipos_arbol := {}          # clave de variante -> {mesh, transforms}
var _rocas_c3: Array = []        # Vector4(x, z, radio, 0) para el suelo
var _zonas_camara: Array = []    # [Vector3, radio]: delante de cada encuadre no crece vegetación alta
var _copas_mat: Array[ShaderMaterial] = []
var _suelo_mat: ShaderMaterial
var _luciernagas_mat: ShaderMaterial
var _luces_noche: Array[OmniLight3D] = []
var _monumental_pos := Vector3.ZERO
var _por_planta := {}            # planta de la biblioteca -> transforms (MultiMesh)
var mm_arboles := 0              # instancias de MultiMesh de árboles (para las pruebas)


func _ready() -> void:
	estilo = Ajustes.ESTILO_ANIME
	hora = 13.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			capturas_dir = a.substr(11)
		elif a.begins_with("--solo="):
			_solo = a.substr(7).split(",")
		elif a.begins_with("--medir="):
			_medir_n = int(a.substr(8))
	_entorno()
	_cielo_c2()
	_camara()
	cam.far = 900.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	_planos_c2 = _calcular_planos()
	_preparar_zonas_camara()
	_bosque_c3()
	_rocas_c3_crear()
	_raices_camino()
	_suelo_c3()
	_sotobosque_c3()
	_tronco_caido()
	_lianas_c3()
	_noche_c3()
	_heroe()
	_ui()
	aplicar_estilo(Ajustes.ESTILO_ANIME)
	set_plano("general")
	if capturas_dir != "":
		_capturar.call_deferred()
	elif _medir_n > 0:
		_medir.call_deferred(_medir_n)


# ------------------------------------------------------------------ encuadres
func _calcular_planos() -> Dictionary:
	var d := super()
	# raíces y rocas al pie del árbol monumental
	var mx := SelvaC2.camino_x(MONUMENTAL_Z) + 9.0
	d["raices"] = [Vector3(SelvaC2.camino_x(MONUMENTAL_Z + 13.0) + 1.0, 2.2, MONUMENTAL_Z + 13.0), Vector3(mx - 1.5, 1.2, MONUMENTAL_Z + 1.0), 56.0]
	return d


## Delante de cada cámara (sus primeros 4 m de vista) no se ponen plantas grandes ni árboles: el
## primer plano no tapa el encuadre ni al personaje.
func _preparar_zonas_camara() -> void:
	for n in _planos_c2:
		var p: Array = _planos_c2[n]
		var pos: Vector3 = p[0]
		var dir: Vector3 = ((p[1] as Vector3) - pos)
		dir.y = 0.0
		dir = dir.normalized()
		for t in [0.0, 1.5, 3.0, 4.5]:
			_zonas_camara.append([pos + dir * t, 1.4 + t * 0.25])
	# el personaje del plano de escala y su recorrido hasta la cámara
	_zonas_camara.append([Vector3(SelvaC2.camino_x(4.0), 0, 4.0), 1.8])


func _en_zona_camara(p: Vector3, margen := 0.0) -> bool:
	for z in _zonas_camara:
		var c: Vector3 = z[0]
		if Vector2(p.x - c.x, p.z - c.z).length() < float(z[1]) + margen:
			return true
	return false


## Las plantas pequeñas de la C2 consultan este método: aquí también evita las zonas de cámara.
func _sobre_roca(p: Vector3) -> bool:
	return super(p) or _en_zona_camara(p)


# ------------------------------------------------------------------ bosque
func _bosque_c3() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C3
	var cort := func(nombre: String, c: Color, musgo: float) -> ShaderMaterial:
		var m := EstiloAnime.material_entorno({"nombre": nombre, "tex": _tex("corteza_col.jpg"), "color": c.srgb_to_linear(), "escala": 0.5, "detalle": 0.35,
			"pintado": 2.5, "musgo": musgo, "bandas": 3})
		m.set_shader_parameter("musgo_color", Vector3(0.06, 0.12, 0.03))
		return m
	var corteza := {
		Esp2.CEIBA: cort.call("corteza_ceiba", Color(0.5, 0.46, 0.42), 0.15),
		Esp2.REDONDA: cort.call("corteza_redonda", Color(0.38, 0.27, 0.2), 0.2),
		Esp2.JOVEN: cort.call("corteza_joven", Color(0.4, 0.32, 0.23), 0.0),
		Esp3.MONUMENTAL: cort.call("corteza_higuera", Color(0.47, 0.43, 0.37), 0.3),
		Esp3.PISOS: cort.call("corteza_pisos", Color(0.35, 0.28, 0.23), 0.15),
		Esp3.CECROPIA: cort.call("corteza_cecropia", Color(0.62, 0.6, 0.54), 0.1),
		Esp3.INCLINADO: cort.call("corteza_inclinado", Color(0.33, 0.24, 0.17), 0.25),
	}
	# verdes por especie: [hoja en sombra, hoja iluminada]; cada variante toma uno
	var verdes := {
		Esp2.CEIBA: [[Color(0.09, 0.24, 0.12), Color(0.28, 0.46, 0.17)], [Color(0.1, 0.25, 0.1), Color(0.33, 0.48, 0.15)]],
		Esp2.REDONDA: [[Color(0.11, 0.28, 0.09), Color(0.36, 0.54, 0.16)], [Color(0.15, 0.29, 0.08), Color(0.44, 0.55, 0.15)], [Color(0.09, 0.26, 0.12), Color(0.3, 0.5, 0.2)]],
		Esp2.JOVEN: [[Color(0.09, 0.26, 0.13), Color(0.27, 0.47, 0.21)], [Color(0.11, 0.28, 0.11), Color(0.32, 0.5, 0.17)]],
		Esp3.MONUMENTAL: [[Color(0.07, 0.2, 0.1), Color(0.24, 0.42, 0.15)]],
		Esp3.PISOS: [[Color(0.07, 0.21, 0.14), Color(0.22, 0.42, 0.24)], [Color(0.08, 0.22, 0.12), Color(0.25, 0.44, 0.2)]],
		Esp3.CECROPIA: [[Color(0.15, 0.28, 0.19), Color(0.47, 0.58, 0.36)], [Color(0.14, 0.27, 0.16), Color(0.42, 0.56, 0.3)]],
		Esp3.INCLINADO: [[Color(0.12, 0.28, 0.1), Color(0.36, 0.52, 0.18)]],
	}
	var n_var := {Esp2.CEIBA: 4, Esp2.REDONDA: 6, Esp2.JOVEN: 5, Esp3.MONUMENTAL: 2, Esp3.PISOS: 4, Esp3.CECROPIA: 4, Esp3.INCLINADO: 3}
	var variantes := {}
	for esp in n_var:
		variantes[esp] = []
		for k in int(n_var[esp]):
			var info := SelvaC3.arbol(esp, SEMILLA_C3 + esp * 97 + k * 7)
			var mesh: ArrayMesh = info["mesh"]
			var v: Array = verdes[esp][k % (verdes[esp] as Array).size()]
			var copa := SelvaC2.material_copa(v[0], v[1])
			_copas_mat.append(copa)
			mesh.surface_set_material(0, corteza[esp])
			mesh.surface_set_material(1, copa)
			(variantes[esp] as Array).append(info)
	# protagonistas en sitios fijos: el monumental al fondo del camino y dos inclinados que lo enmarcan
	var mz := MONUMENTAL_Z
	_monumental_pos = Vector3(SelvaC2.camino_x(mz) + 9.0, 0, mz)
	_poner_arbol(Esp3.MONUMENTAL, 0, _monumental_pos, 20.0, Vector3.ONE, variantes, false)
	_poner_arbol(Esp3.MONUMENTAL, 1, Vector3(-26.0, 0, -78.0), 140.0, Vector3.ONE * 1.1, variantes, false)
	_poner_arbol(Esp3.INCLINADO, 0, Vector3(SelvaC2.camino_x(-12.0) - 4.6, 0, -12.0), -8.0, Vector3.ONE, variantes, false)
	_poner_arbol(Esp3.INCLINADO, 1, Vector3(SelvaC2.camino_x(-31.0) + 4.8, 0, -31.0), 172.0, Vector3(1.0, 0.95, 1.0), variantes, false)
	_poner_arbol(Esp2.CEIBA, 0, Vector3(-11.0, 0, -20.0), 30.0, Vector3.ONE, variantes, false)
	_poner_arbol(Esp3.PISOS, 0, Vector3(7.5, 0, -6.5), 0.0, Vector3.ONE * 0.9, variantes, false)
	_poner_arbol(Esp3.CECROPIA, 0, Vector3(-6.0, 0, -4.0), 0.0, Vector3.ONE, variantes, false)
	_poner_arbol(Esp2.REDONDA, 0, Vector3(-7.0, 0, -9.5), 60.0, Vector3.ONE, variantes, false)
	_poner_arbol(Esp2.JOVEN, 0, Vector3(-5.5, 0, 6.0), 0.0, Vector3.ONE, variantes, false)
	# bosque cercano: especies según la distancia al camino
	var cerca_pesos := [[Esp2.REDONDA, 0.24], [Esp2.JOVEN, 0.16], [Esp3.CECROPIA, 0.18], [Esp3.PISOS, 0.12], [-1, 0.16], [Esp3.INCLINADO, 0.06], [Esp2.CEIBA, 0.08]]
	var lejos_pesos := [[Esp2.CEIBA, 0.2], [Esp2.REDONDA, 0.24], [Esp3.PISOS, 0.2], [Esp3.CECROPIA, 0.1], [Esp2.JOVEN, 0.1], [-1, 0.1], [Esp3.MONUMENTAL, 0.06]]
	var radio := {Esp2.CEIBA: 6.0, Esp2.REDONDA: 3.6, Esp2.JOVEN: 2.2, Esp3.MONUMENTAL: 10.0, Esp3.PISOS: 4.0, Esp3.CECROPIA: 2.4, Esp3.INCLINADO: 3.2, -1: 2.4}
	var colocados := 0
	var intentos := 0
	while colocados < 140 and intentos < 8000:
		intentos += 1
		var p := Vector3(rng.randf_range(-55.0, 55.0), 0, rng.randf_range(-105.0, 24.0))
		var dc := SelvaC2.distancia_camino(p)
		if dc < 4.4 or (p.z > 6.0 and dc < 9.0) or _en_zona_camara(p, 3.5) or _en_corredor(p):
			continue
		var esp: int = _elegir(cerca_pesos if dc < 12.0 else lejos_pesos, rng)
		if not _libre(p, float(radio[esp])):
			continue
		if esp == -1:
			_palma(p, rng)
		else:
			var s := rng.randf_range(0.82, 1.2)
			var giro := rng.randf() * 360.0
			if esp == Esp3.INCLINADO:
				# se inclina hacia el camino
				var hacia := Vector2(SelvaC2.camino_x(p.z) - p.x, 0.0)
				giro = 0.0 if hacia.x > 0.0 else 180.0
				giro += rng.randf_range(-25.0, 25.0)
			_poner_arbol(esp, rng.randi() % (variantes[esp] as Array).size(), p, giro, Vector3(s, s * rng.randf_range(0.88, 1.15), s), variantes, false)
		colocados += 1
	# anillo lejano y masa de copas del horizonte (como en la C2, pero con más especies)
	var lejanos := 0
	intentos = 0
	while lejanos < 190 and intentos < 5000:
		intentos += 1
		var ang := rng.randf_range(-PI, PI)
		var r := rng.randf_range(58.0, 200.0)
		var p := Vector3(sin(ang) * r, 0, -cos(ang) * r - 25.0)
		if not _libre(p, 4.5):
			continue
		var esp: int = _elegir([[Esp2.CEIBA, 0.3], [Esp2.REDONDA, 0.35], [Esp3.PISOS, 0.25], [Esp3.MONUMENTAL, 0.1]], rng)
		var s := rng.randf_range(1.2, 1.8)
		_poner_arbol(esp, rng.randi() % (variantes[esp] as Array).size(), p, rng.randf() * 360.0, Vector3(s, s * rng.randf_range(0.85, 1.2), s), variantes, true)
		lejanos += 1
	especies["lejano"] = lejanos
	var muro := _malla(SelvaC2.muro_lejano(SEMILLA_C2 + 3, Vector3(0, 0, -25.0), 175.0, 235.0, 150), Vector3.ZERO)
	muro.name = "Selva_lejana"
	muro.set_surface_override_material(0, _copas_mat[0])
	muro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# una MultiMesh por variante
	for clave in _tipos_arbol:
		var t: Dictionary = _tipos_arbol[clave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = t["mesh"]
		var ts: Array = t["ts"]
		mm.instance_count = ts.size()
		for i in ts.size():
			mm.set_instance_transform(i, ts[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Arboles_" + String(clave)
		mmi.multimesh = mm
		# el anillo lejano queda dentro de la bruma: no proyecta sombras (ahorra el pase de sombras)
		if String(clave).ends_with("_lejos"):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		mm_arboles += ts.size()
	stats["variantes_arbol"] = n_var.values().reduce(func(a, b): return a + b, 0)
	stats["multimesh_arbol"] = _tipos_arbol.size()


## Corredor de vista desde el encuadre general hasta el árbol monumental: ahí no se ponen árboles,
## para que el punto focal se vea al fondo del camino.
func _en_corredor(p: Vector3) -> bool:
	var a: Vector3 = (_planos_c2["general"] as Array)[0]
	var b := _monumental_pos
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
	if t < 0.25 or t > 0.85:
		return false
	return Vector2(p.x, p.z).distance_to(Vector2(a.x, a.z) + ab * t) < 5.0


func _elegir(pesos: Array, rng: RandomNumberGenerator) -> int:
	var u := rng.randf()
	var acc := 0.0
	for e in pesos:
		acc += float(e[1])
		if u < acc:
			return int(e[0])
	return int(pesos[pesos.size() - 1][0])


func _poner_arbol(esp: int, k: int, p: Vector3, giro: float, s: Vector3, variantes: Dictionary, lejano: bool) -> void:
	var info: Dictionary = (variantes[esp] as Array)[k]
	p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - 0.1
	# una MultiMesh por variante y por sector de 60 m: así la cámara y las sombras descartan los
	# sectores que no ve (una sola MultiMesh para todo el bosque se dibujaría entera siempre)
	var clave := "%d_%d_s%d_%d%s" % [esp, k, floori(p.x / 60.0), floori(p.z / 60.0), "_lejos" if lejano else ""]
	if not _tipos_arbol.has(clave):
		_tipos_arbol[clave] = {"mesh": info["mesh"], "ts": []}
	(_tipos_arbol[clave]["ts"] as Array).append(Transform3D(Basis(Vector3.UP, deg_to_rad(giro)).scaled(s), p))
	var nombre: String = {Esp2.CEIBA: "ceiba", Esp2.REDONDA: "redonda", Esp2.JOVEN: "joven", Esp3.MONUMENTAL: "monumental", Esp3.PISOS: "pisos",
		Esp3.CECROPIA: "cecropia", Esp3.INCLINADO: "inclinado"}[esp]
	var ocupa: float = {Esp2.CEIBA: 6.0, Esp2.REDONDA: 3.6, Esp2.JOVEN: 2.2, Esp3.MONUMENTAL: 9.0, Esp3.PISOS: 3.6, Esp3.CECROPIA: 2.2, Esp3.INCLINADO: 2.6}[esp]
	_ocupar(p, ocupa * s.x)
	if lejano:
		return
	especies_c3[nombre] = int(especies_c3.get(nombre, 0)) + 1
	_huellas.append(Vector4(p.x, p.z, maxf(float(info["radio_copa"]) * s.x, 2.0), 0.0))


# ------------------------------------------------------------------ rocas y raíces
func _rocas_c3_crear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C3 + 7
	var variantes := []
	for k in 8:
		variantes.append(SelvaC2.roca(SEMILLA_C3 + 31 * k, Vector3(1.0, rng.randf_range(0.6, 0.85), rng.randf_range(0.75, 0.95)), rng.randi_range(7, 10)))
	var guijarro := SelvaC2.roca(SEMILLA_C3 + 999, Vector3(1.0, 0.6, 0.8), 6)
	var tonos := [Color(0.4, 0.39, 0.36), Color(0.36, 0.37, 0.35), Color(0.43, 0.4, 0.35)]
	var mats := []
	for t in tonos:
		for musgo in [false, true]:
			var m := EstiloAnime.material_entorno({"nombre": "roca_c3", "tex": _tex("basalto_col.jpg"), "color": (t as Color).srgb_to_linear(), "escala": 0.35,
				"detalle": 0.28, "pintado": 3.0, "musgo": 0.26 if musgo else 0.0, "bandas": 3})
			m.set_shader_parameter("musgo_color", Vector3(0.06, 0.12, 0.03))
			mats.append(m)
	var mz := MONUMENTAL_Z
	# grupos: [centro, tamaño de la roca mayor, rocas medianas, musgo]
	var grupos := [
		[Vector3(SelvaC2.camino_x(-12.0) - 4.4, 0, -12.3), 1.5, 4, true],
		[Vector3(SelvaC2.camino_x(-27.0) + 4.6, 0, -27.0), 1.1, 3, false],
		[_monumental_pos + Vector3(-5.5, 0, 5.0), 1.3, 4, true],
		[_monumental_pos + Vector3(3.0, 0, 6.5), 0.8, 2, true],
		[Vector3(-12.5, 0, -16.0), 1.0, 2, true],
		[Vector3(SelvaC2.camino_x(3.0) + 3.9, 0, 3.0), 0.7, 2, false],
		[Vector3(SelvaC2.camino_x(-62.0) + 5.0, 0, -62.0), 1.4, 3, true],
		[Vector3(-20.0, 0, -36.0), 1.2, 3, false],
		[Vector3(SelvaC2.camino_x(mz + 14.0) - 4.2, 0, mz + 14.0), 0.9, 3, true],
	]
	var por_clave := {}
	var poner := func(mesh_i: int, mat_i: int, p: Vector3, tam: Vector3, giro: float) -> void:
		var clave := "%d_%d" % [mesh_i, mat_i]
		if not por_clave.has(clave):
			por_clave[clave] = []
		p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - tam.y * 0.18
		var b := Basis(Vector3.UP, giro) * Basis(Vector3(1, 0, 0), rng.randf_range(-0.08, 0.08))
		(por_clave[clave] as Array).append(Transform3D(b.scaled(tam), p))
	var n := 0
	for g in grupos:
		var c: Vector3 = g[0]
		var t0: float = g[1]
		var musgo: bool = g[3]
		var tono := rng.randi() % tonos.size()
		poner.call(rng.randi() % 8, tono * 2 + (1 if musgo else 0), c, Vector3(t0, t0, t0) * rng.randf_range(0.9, 1.1), rng.randf() * TAU)
		_rocas_c3.append(Vector4(c.x, c.z, t0 * 0.95, 0.0))
		_rocas_pos.append([Vector2(c.x, c.z), t0 + 0.5])
		_ocupar(c, t0)
		n += 1
		for k in int(g[2]):
			var t := t0 * rng.randf_range(0.3, 0.6)
			var a := rng.randf() * TAU
			var p := c + Vector3(cos(a), 0, sin(a)) * (t0 + t) * rng.randf_range(0.65, 0.9)
			if SelvaC2.distancia_camino(p) < 1.6:
				continue
			poner.call(rng.randi() % 8, tono * 2 + (1 if musgo and k == 0 else 0), p, Vector3(t, t, t), rng.randf() * TAU)
			_rocas_c3.append(Vector4(p.x, p.z, t * 0.9, 0.0))
			_rocas_pos.append([Vector2(p.x, p.z), t + 0.3])
			n += 1
		# piedrecillas sueltas alrededor del grupo
		for k in rng.randi_range(5, 9):
			var a := rng.randf() * TAU
			var p := c + Vector3(cos(a), 0, sin(a)) * t0 * rng.randf_range(1.3, 2.4)
			var t := rng.randf_range(0.07, 0.18)
			poner.call(8, tono * 2, p, Vector3(t, t, t), rng.randf() * TAU)
	# piedras sueltas por el bosque y algunas en la orilla del camino
	var sueltas := 0
	while sueltas < 22:
		var p := Vector3(rng.randf_range(-32, 32), 0, rng.randf_range(-75, 15))
		var dc := SelvaC2.distancia_camino(p)
		if dc < 1.7 or not _libre(p, 0.8):
			continue
		var t := rng.randf_range(0.15, 0.55) if dc > 3.0 else rng.randf_range(0.1, 0.25)
		poner.call(rng.randi() % 8 if t > 0.2 else 8, (rng.randi() % tonos.size()) * 2, p, Vector3(t, t, t), rng.randf() * TAU)
		_rocas_c3.append(Vector4(p.x, p.z, t, 0.0))
		sueltas += 1
		n += 1
	variantes.append(guijarro)
	for clave in por_clave:
		var partes := String(clave).split("_")
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = variantes[int(partes[0])]
		var ts: Array = por_clave[clave]
		mm.instance_count = ts.size()
		for i in ts.size():
			mm.set_instance_transform(i, ts[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Rocas_" + String(clave)
		mmi.multimesh = mm
		mmi.material_override = mats[int(partes[1])]
		add_child(mmi)
	stats["rocas_c3"] = n


## Raíces expuestas de los árboles cercanos al camino, que se acercan a la orilla sin cruzar el
## centro del camino (se puede caminar por él). Todas en una sola malla.
func _raices_camino() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C3 + 17
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	for h in _huellas:
		var p := Vector3(h.x, 0, h.y)
		var dc := SelvaC2.distancia_camino(p)
		if dc > 11.0 or h.z < 3.0:
			continue
		var cx := SelvaC2.camino_x(p.z)
		for k in rng.randi_range(2, 3):
			var hacia := Vector3(signf(cx - p.x), 0, rng.randf_range(-0.9, 0.9)).normalized()
			var largo := clampf(dc - 1.7, 2.0, 7.0) * rng.randf_range(0.7, 1.0)
			var base := p
			base.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2)
			SelvaC3.raiz(st, base + hacia * 0.4, hacia, rng.randf_range(0.5, 1.1), largo, rng.randf_range(0.16, 0.26), rng)
			n += 1
		# y alguna raíz hacia el lado contrario
		var otra := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		SelvaC3.raiz(st, Vector3(p.x, SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2), p.z) + otra * 0.4, otra, 0.7, rng.randf_range(2.0, 4.0), 0.18, rng)
		n += 1
	var mi := _malla(st.commit(), Vector3.ZERO)
	mi.name = "Raices_C3"
	var m := EstiloAnime.material_entorno({"nombre": "raiz", "tex": _tex("corteza_col.jpg"), "color": Color(0.36, 0.28, 0.21).srgb_to_linear(), "escala": 0.6,
		"detalle": 0.3, "pintado": 2.5, "musgo": 0.1, "bandas": 3})
	m.set_shader_parameter("musgo_color", Vector3(0.06, 0.12, 0.03))
	mi.set_surface_override_material(0, m)
	stats["raices_c3"] = n


func _suelo_c3() -> void:
	var mi := _malla(SelvaC2.malla_suelo(SUELO_LADO, 220, SEMILLA_C2), Vector3.ZERO)
	mi.name = "Suelo_Selva_C3"
	_huellas.sort_custom(func(a: Vector4, b: Vector4) -> bool: return Vector2(a.x, a.y + 15.0).length() < Vector2(b.x, b.y + 15.0).length())
	_suelo_mat = SelvaC3.material_suelo(_huellas, _rocas_c3)
	mi.set_surface_override_material(0, _suelo_mat)


# ------------------------------------------------------------------ sotobosque
func _sotobosque_c3() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C3 + 13
	# plantas grandes con escalas contenidas, a 3 m o más del eje del camino
	var grandes := {"Monstera_0": 0.95, "Monstera_1": 0.9, "Monstera_2": 1.05, "Helecho_Arbol_0": 0.6, "Helecho_Arbol_1": 0.55, "Platanera_0": 0.72, "Platanera_1": 0.68,
		"V_shrub_02_0": 0.9, "V_shrub_02_1": 0.85}
	var nombres := grandes.keys()
	var por_planta := _por_planta
	var n := 0
	for h in _huellas:
		if Vector2(h.x, h.y + 20.0).length() > 48.0:
			continue
		for k in rng.randi_range(1, 3):
			var a := rng.randf() * TAU
			var p := Vector3(h.x + cos(a) * rng.randf_range(1.2, 3.2), 0, h.y + sin(a) * rng.randf_range(1.2, 3.2))
			if SelvaC2.distancia_camino(p) < 3.0 or _sobre_roca(p) or _en_zona_camara(p, 1.0):
				continue
			var nom: String = nombres[rng.randi() % nombres.size()]
			_agregar_planta(por_planta, nom, p, rng.randf() * TAU, float(grandes[nom]) * rng.randf_range(0.8, 1.15))
			n += 1
	# viñeta de vegetación junto al camino para el encuadre de vegetación: alturas escalonadas
	var zv := -1.0
	for e in [["Monstera_0", 3.6, 0.3, 0.85], ["Helecho_Arbol_1", 5.8, -1.8, 0.55], ["V_shrub_02_0", 4.6, 1.2, 0.8], ["Platanera_1", 6.6, 0.0, 0.7]]:
		var p := Vector3(SelvaC2.camino_x(zv + e[2]) + e[1], 0, zv + e[2])
		if _en_zona_camara(p):
			continue
		_agregar_planta(por_planta, e[0], p, rng.randf() * TAU, e[3])
		n += 1
	for nom in por_planta:
		_multimesh_planta(nom, por_planta[nom])
	stats["plantas_grandes"] = n
	# plantas pequeñas en manchas (MultiMesh de la C2), más bajas en la orilla del camino
	var pequenas := [["V_fern_02_1", 1.8, 650, 1.7, 6.0], ["V_fern_02_0", 2.1, 320, 2.2, 8.0], ["V_grass_medium_02_1", 3.0, 700, 1.5, 9.0], ["V_grass_medium_02_2", 2.8, 500, 1.4, 12.0],
		["V_calathea_orbifolia_01_0", 1.7, 140, 2.0, 6.0], ["V_anthurium_botany_01_0", 1.5, 110, 2.2, 7.0], ["V_shrub_02_0", 0.8, 90, 2.8, 10.0]]
	for e in pequenas:
		_grupo_pequeno(e[0], e[1], e[2], e[3], e[4], rng)


func _agregar_planta(por_planta: Dictionary, nom: String, p: Vector3, giro: float, s: float) -> void:
	p.y = SelvaC2.altura_suelo(p.x, p.z, SEMILLA_C2) - 0.03
	if not por_planta.has(nom):
		por_planta[nom] = []
	(por_planta[nom] as Array).append(Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * s), p))


## Una MultiMesh por planta de la biblioteca, con los materiales anime puestos en una copia de la malla.
func _multimesh_planta(nom: String, ts: Array) -> void:
	var orig: Mesh = _biblioteca().get(nom)
	if orig == null:
		return
	var mesh: Mesh = orig.duplicate()
	var centros: Array = EstiloAnime.centros_glb(LIB_GLB).get(nom, [])
	for sf in mesh.get_surface_count():
		var om := orig.surface_get_material(sf)
		var v13 := _v13_de(om)
		mesh.surface_set_material(sf, _veg_c2(_anime_para_vegetal(String(om.resource_name) if om else "", v13, centros, sf)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = ts.size()
	for i in ts.size():
		mm.set_instance_transform(i, ts[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Plantas_" + nom
	mmi.multimesh = mm
	add_child(mmi)


func _palma(p: Vector3, rng: RandomNumberGenerator) -> void:
	_agregar_planta(_por_planta, "Palma_%d" % rng.randi_range(0, 2), p, rng.randf() * TAU, rng.randf_range(0.5, 0.72))
	_ocupar(p, 2.0)
	especies_c3["palma"] = int(especies_c3.get("palma", 0)) + 1


# ------------------------------------------------------------------ lianas y noche
func _lianas_c3() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_C3 + 23
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# lianas que cruzan por encima del camino entre las copas de ambos lados
	for z in [-8.0, -17.0, -24.0, -36.0, -52.0]:
		var cx := SelvaC2.camino_x(z)
		var a := Vector3(cx - rng.randf_range(4.5, 6.5), rng.randf_range(8.0, 11.0), z + rng.randf_range(-1.5, 1.5))
		var b := Vector3(cx + rng.randf_range(4.5, 6.5), rng.randf_range(8.0, 11.0), z + rng.randf_range(-1.5, 1.5))
		var pts := []
		for i in 9:
			var t := float(i) / 8.0
			pts.append(a.lerp(b, t) + Vector3(0, -rng.randf_range(2.0, 3.2) * 4.0 * t * (1.0 - t), 0))
		SelvaC2._tubo(st, pts, [0.06, 0.06, 0.05, 0.05, 0.05, 0.05, 0.05, 0.06, 0.06], 5, rng, 0.0)
		# algunas cuelgan sueltas desde la liana
		for k in 2:
			SelvaC2._liana(st, a.lerp(b, rng.randf_range(0.2, 0.8)) - Vector3(0, 1.5, 0), rng.randf_range(1.5, 3.5), rng)
	var mi := _malla(st.commit(), Vector3.ZERO)
	mi.name = "Lianas_C3"
	mi.set_surface_override_material(0, EstiloAnime.material_entorno({"nombre": "liana", "color": Color(0.3, 0.36, 0.16).srgb_to_linear(), "detalle": 0.0, "bandas": 3}))


func _noche_c3() -> void:
	var centros := []
	for z in [10.0, 4.0, -2.0, -9.0, -16.0, -24.0, -32.0, -40.0]:
		for lado in [-1.0, 1.0]:
			centros.append(Vector3(SelvaC2.camino_x(z) + lado * 3.8, SelvaC2.altura_suelo(SelvaC2.camino_x(z), z, SEMILLA_C2), z))
	var mi := _malla(SelvaC3.luciernagas(centros, 220, SEMILLA_C3), Vector3.ZERO)
	mi.name = "Luciernagas"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 4.0
	_luciernagas_mat = SelvaC3.material_luciernaga()
	mi.set_surface_override_material(0, _luciernagas_mat)
	# tres luces suaves junto al camino: iluminación selectiva, no general
	for z in [2.0, -14.0, -30.0]:
		var l := OmniLight3D.new()
		l.name = "Luz_noche"
		l.light_color = Color(0.62, 0.95, 0.55)
		l.light_energy = 0.9
		l.omni_range = 7.0
		l.shadow_enabled = false
		l.position = Vector3(SelvaC2.camino_x(z) + (3.0 if int(z) % 2 == 0 else -3.0), 1.4, z)
		add_child(l)
		_luces_noche.append(l)


## 1 de noche cerrada, 0 de día, con rampas al anochecer y al amanecer.
static func factor_noche(h: float) -> float:
	h = fposmod(h, 24.0)
	if h >= 12.0:
		return smoothstep(19.0, 20.5, h)
	return 1.0 - smoothstep(4.5, 6.0, h)


func _luz_anime(h: float) -> void:
	super(h)
	var nf := factor_noche(h)
	if nf > 0.0:
		var e := env_anime
		# luna fría y más presente; ambiente verde azulado; bruma más clara que las siluetas
		sun.light_energy = lerpf(sun.light_energy, 0.72, nf)
		sun.light_color = sun.light_color.lerp(Color(0.6, 0.74, 1.0), nf)
		e.ambient_light_color = e.ambient_light_color.lerp(Color(0.32, 0.46, 0.58), nf)
		e.ambient_light_energy = lerpf(e.ambient_light_energy, 0.62, nf)
		var bruma := e.fog_light_color.lerp(Color(0.1, 0.16, 0.24), nf)
		e.fog_light_color = bruma
		_sky_c2.ground_horizon_color = bruma
		_sky_c2.ground_bottom_color = bruma * 0.6
		_sky_c2.sky_horizon_color = _sky_c2.sky_horizon_color.lerp(Color(0.12, 0.19, 0.3), nf)
	for m in _copas_mat:
		m.set_shader_parameter("borde_fuerza", 0.55 * nf)
		m.set_shader_parameter("borde_color", Vector3(0.5, 0.8, 0.95))
		m.set_shader_parameter("borde_ancho", 0.35)
	if _suelo_mat:
		_suelo_mat.set_shader_parameter("luna", nf)
	if _luciernagas_mat:
		_luciernagas_mat.set_shader_parameter("intensidad", 2.6 * nf)
	for l in _luces_noche:
		l.visible = nf > 0.3
		l.light_energy = 0.9 * nf


# ------------------------------------------------------------------ estado
func aplicar_estilo(_e: int) -> void:
	super(Ajustes.ESTILO_ANIME)


func _refresh_info() -> void:
	if _info == null:
		return
	_info.text = "ENTORNO ANIME C3 · hora %.1f · plano: %s · contornos: %s\n1-8 plano · H hora · O contornos · Esc menú" % [
		hora, plano, "sí" if Ajustes.contornos else "no"]


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_TAB:
			return
		if k == KEY_8:
			set_plano("raices")
			return
	super(ev)


# ------------------------------------------------------------------ capturas
func _capturar() -> void:
	DirAccess.make_dir_recursive_absolute(capturas_dir)
	await get_tree().create_timer(0.6).timeout
	var lista := []
	for p in ["general", "profundidad", "copas", "vegetacion", "rocas", "raices", "terreno", "escala"]:
		lista.append([13.0, p])
	for h in [6.5, 9.0, 16.5, 18.2, 19.5, 21.0, 0.0]:
		lista.append([h, "general"])
	# la noche también de cerca: vegetación y escala con el personaje
	lista.append([21.0, "vegetacion"])
	lista.append([21.0, "escala"])
	for c in lista:
		if not _solo.is_empty() and not (c[1] + "@" + str(c[0]) in _solo or (c[0] == 13.0 and c[1] in _solo)):
			continue
		Ajustes.contornos = true
		hora = c[0]
		aplicar_estilo(Ajustes.ESTILO_ANIME)
		set_plano(c[1])
		await _shot("c3_anime_%s_h%s" % [c[1], ("%04.1f" % float(c[0])).replace(".", "_")])
	get_tree().quit()


func _medir(fotogramas: int) -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	hora = 13.0
	aplicar_estilo(Ajustes.ESTILO_ANIME)
	set_plano("general")
	for i in 30:
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	for i in fotogramas:
		await get_tree().process_frame
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(fotogramas)
	print("[medida] estilo=anime_c3 fotogramas=%d ms=%.2f fps=%.2f dibujos=%d triangulos=%d" % [fotogramas, ms, 1000.0 / ms,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	get_tree().quit()
