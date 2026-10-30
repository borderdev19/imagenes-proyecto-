class_name SelvaC3
extends RefCounted
## Etapa C del estilo anime, revisión C3: especies de árbol nuevas, raíces expuestas, luciérnagas y
## suelo con rocas integradas. Se apoya en SelvaC2 (tubos, racimos, lianas, rocas, suelo) sin
## modificarla: la escena C2 sigue igual.
##
## Especies nuevas (además de ceiba, redonda y joven de la C2):
## - MONUMENTAL: higuera gigante de 26-32 m, tronco de varios fustes trenzados, raíces que serpentean
##   por el suelo, raíces aéreas y copa ancha en varias capas. Es el punto focal del camino.
## - PISOS: tronco recto con verticilos de ramas horizontales; copa en pisos planos (silueta de pagoda).
## - CECROPIA: tronco fino y claro, ramas en candelabro y rosetas planas en las puntas.
## - INCLINADO: tronco que se curva y se inclina (enmarca el camino), copa alargada al final.
## Todas las ramas terminan en ramitas con su racimo, para que tronco, ramas y hojas se lean unidos.

enum Especie {MONUMENTAL = 10, PISOS, CECROPIA, INCLINADO}

const SH_SUELO_C3 := preload("res://assets/materials/anime/anime_suelo_selva_c3.gdshader")
const SH_LUCIERNAGA := preload("res://assets/materials/anime/anime_luciernaga.gdshader")


static func arbol(especie: int, semilla: int) -> Dictionary:
	if especie < Especie.MONUMENTAL:
		return SelvaC2.arbol(especie, semilla)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var corteza := SurfaceTool.new()
	corteza.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hojas := SurfaceTool.new()
	hojas.begin(Mesh.PRIMITIVE_TRIANGLES)
	var info := {"racimos": 0, "altura": 0.0, "radio_copa": 0.0, "raices": 0}
	match especie:
		Especie.MONUMENTAL:
			_monumental(corteza, hojas, rng, info)
		Especie.PISOS:
			_pisos(corteza, hojas, rng, info)
		Especie.CECROPIA:
			_cecropia(corteza, hojas, rng, info)
		_:
			_inclinado(corteza, hojas, rng, info)
	var mesh := corteza.commit()
	hojas.commit(mesh)
	info["mesh"] = mesh
	return info


## Rama que termina en 2-3 ramitas, cada una con su racimo, y un racimo pequeño a media rama.
static func _rama(c: SurfaceTool, h: SurfaceTool, ini: Vector3, fin: Vector3, r: float, radio: float, aplastar: float, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var mid := ini.lerp(fin, 0.5) + Vector3(0, (fin - ini).length() * 0.08, 0)
	SelvaC2._tubo(c, [ini, mid, fin], [r, r * 0.6, r * 0.32], 6, rng, 0.06)
	var dir := (fin - ini).normalized()
	for k in rng.randi_range(2, 3):
		var lado := dir.cross(Vector3.UP).normalized()
		if lado.length() < 0.1:
			lado = Vector3.RIGHT
		var d := (dir * 0.6 + lado * rng.randf_range(-0.9, 0.9) + Vector3(0, rng.randf_range(0.2, 0.7), 0)).normalized()
		var punta := fin + d * radio * rng.randf_range(0.55, 0.85)
		SelvaC2._tubo(c, [fin, punta], [r * 0.3, 0.025], 4, rng, 0.0)
		SelvaC2._racimo(h, punta + Vector3(0, radio * 0.15, 0), radio * rng.randf_range(0.7, 0.95), aplastar, rng)
		info["racimos"] += 1
	SelvaC2._racimo(h, fin + Vector3(0, radio * 0.25, 0), radio, aplastar, rng)
	SelvaC2._racimo(h, mid + Vector3(0, radio * 0.3, 0), radio * 0.55, aplastar, rng)
	info["racimos"] += 2


## Raíz expuesta: sale del tronco a 'alto' metros, baja hasta el suelo y serpentea por él.
static func raiz(c: SurfaceTool, base: Vector3, dir: Vector3, alto: float, largo: float, r: float, rng: RandomNumberGenerator) -> void:
	var pts := [base + Vector3(0, alto, 0)]
	var rad := [r]
	var p := base + dir * largo * 0.18 + Vector3(0, alto * 0.35, 0)
	pts.append(p)
	rad.append(r * 0.85)
	var lado := dir.cross(Vector3.UP).normalized()
	var n := 5
	for i in n:
		var t := float(i + 1) / float(n)
		var q := base + dir * largo * lerpf(0.3, 1.0, t) + lado * sin(t * 5.0 + rng.randf() * 0.5) * largo * 0.08
		# medio enterrada: el centro queda por debajo del suelo
		q.y = -lerpf(r * 0.25, r * 0.6, t)
		pts.append(q)
		rad.append(lerpf(r * 0.7, 0.04, t))
	SelvaC2._tubo(c, pts, rad, 7, rng, 0.07)


static func _monumental(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(26.0, 32.0)
	# fustes trenzados alrededor de un núcleo
	var nucleo := []
	var rn := []
	for i in 11:
		var t := float(i) / 10.0
		nucleo.append(Vector3(sin(t * 2.0) * 0.4, -0.3 + (alto * 0.78) * t, cos(t * 1.7) * 0.3))
		rn.append(lerpf(1.5, 0.7, t))
	SelvaC2._tubo(c, nucleo, rn, 14, rng, 0.06)
	var n_fustes := rng.randi_range(4, 5)
	for k in n_fustes:
		var a0 := TAU * float(k) / float(n_fustes)
		var pts := []
		var rad := []
		for i in 11:
			var t := float(i) / 10.0
			var a := a0 + t * rng.randf_range(1.2, 1.8)
			var rr := lerpf(1.55, 0.55, t)
			pts.append((nucleo[i] as Vector3) + Vector3(cos(a) * rr, 0, sin(a) * rr))
			rad.append(lerpf(0.75, 0.32, t))
		SelvaC2._tubo(c, pts, rad, 8, rng, 0.08)
	# raíces que serpentean por el suelo
	var n_raices := rng.randi_range(8, 10)
	for k in n_raices:
		var a := TAU * float(k) / float(n_raices) + rng.randf_range(-0.25, 0.25)
		var d := Vector3(cos(a), 0, sin(a))
		raiz(c, d * 1.3, d, rng.randf_range(2.5, 4.5), rng.randf_range(6.0, 11.0), rng.randf_range(0.42, 0.6), rng)
		info["raices"] += 1
	# copa: ramas principales largas en dos capas, con ramitas y racimos grandes
	var cima := Vector3((nucleo[10] as Vector3).x, alto * 0.78, (nucleo[10] as Vector3).z)
	var radio_copa := 0.0
	var n_ramas := rng.randi_range(8, 10)
	for k in n_ramas:
		var a := TAU * float(k) / float(n_ramas) + rng.randf_range(-0.2, 0.2)
		var baja := k % 2 == 0
		var y0 := cima.y - (rng.randf_range(2.5, 4.5) if baja else rng.randf_range(0.0, 1.5))
		var ini := Vector3(cima.x, y0, cima.z)
		var largo := rng.randf_range(7.0, 11.0) if baja else rng.randf_range(5.0, 8.0)
		var fin := ini + Vector3(cos(a) * largo, rng.randf_range(1.5, 4.0) if baja else rng.randf_range(3.0, 5.5), sin(a) * largo)
		_rama(c, h, ini, fin, 0.5 if baja else 0.4, rng.randf_range(2.6, 3.4), 0.5, rng, info)
		radio_copa = maxf(radio_copa, Vector2(fin.x, fin.z).length() + 3.0)
		# raíces aéreas y lianas desde las ramas bajas
		if baja and rng.randf() < 0.7:
			var p := ini.lerp(fin, rng.randf_range(0.5, 0.8))
			SelvaC2._tubo(c, [p, p + Vector3(rng.randf_range(-0.3, 0.3), -p.y * 0.5, rng.randf_range(-0.3, 0.3)), Vector3(p.x, -0.2, p.z)], [0.07, 0.06, 0.09], 5, rng, 0.0)
		if rng.randf() < 0.8:
			SelvaC2._liana(c, fin, rng.randf_range(6.0, 14.0), rng)
	for k in 3:
		SelvaC2._racimo(h, cima + Vector3(rng.randf_range(-2.5, 2.5), rng.randf_range(4.0, 6.0), rng.randf_range(-2.5, 2.5)), rng.randf_range(3.0, 3.6), 0.5, rng)
		info["racimos"] += 1
	info["altura"] = alto + 4.0
	info["radio_copa"] = radio_copa


static func _pisos(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(10.0, 15.0)
	var r0 := rng.randf_range(0.3, 0.42)
	var pts := SelvaC2._tronco_pts(rng, alto, 8, 0.25)
	var radios := []
	for i in pts.size():
		var t := float(i) / float(pts.size() - 1)
		radios.append(r0 * (1.0 - 0.6 * t) + r0 * 0.8 * exp(-(pts[i] as Vector3).y * 1.8))
	SelvaC2._tubo(c, pts, radios, 9, rng, 0.05)
	var pisos := rng.randi_range(3, 4)
	var radio_copa := 0.0
	for p in pisos:
		var t := float(p) / float(pisos)
		var y := lerpf(alto * 0.45, alto, t)
		var eje: Vector3 = pts[int(lerpf(0.45, 1.0, t) * (pts.size() - 1))]
		var ini := Vector3(eje.x, y, eje.z)
		var n := rng.randi_range(4, 6)
		var largo := lerpf(5.0, 1.8, t) * rng.randf_range(0.85, 1.15)
		var giro := rng.randf() * TAU
		for k in n:
			var a := giro + TAU * float(k) / float(n) + rng.randf_range(-0.25, 0.25)
			var fin := ini + Vector3(cos(a) * largo, largo * rng.randf_range(0.05, 0.18), sin(a) * largo)
			_rama(c, h, ini, fin, r0 * lerpf(0.4, 0.25, t), lerpf(1.9, 1.2, t), 0.32, rng, info)
			radio_copa = maxf(radio_copa, largo + 1.8)
	SelvaC2._racimo(h, pts[pts.size() - 1] + Vector3(0, 0.8, 0), 1.3, 0.5, rng)
	info["racimos"] += 1
	info["altura"] = alto + 1.5
	info["radio_copa"] = radio_copa


static func _cecropia(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(9.0, 13.0)
	var r0 := rng.randf_range(0.16, 0.22)
	var pts := SelvaC2._tronco_pts(rng, alto, 7, 0.7)
	var radios := []
	for i in pts.size():
		radios.append(r0 * (1.0 - 0.4 * float(i) / float(pts.size() - 1)) + r0 * 0.6 * exp(-(pts[i] as Vector3).y * 2.5))
	SelvaC2._tubo(c, pts, radios, 7, rng, 0.03)
	# raíces zanco al pie
	for k in rng.randi_range(3, 5):
		var a := rng.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		SelvaC2._tubo(c, [Vector3(0, rng.randf_range(0.8, 1.4), 0), d * 0.5 + Vector3(0, 0.4, 0), d * rng.randf_range(0.9, 1.3) + Vector3(0, -0.1, 0)], [0.07, 0.06, 0.05], 5, rng, 0.0)
	var cima: Vector3 = pts[pts.size() - 1]
	var n := rng.randi_range(3, 5)
	var radio_copa := 0.0
	for k in n:
		var a := TAU * float(k) / float(n) + rng.randf_range(-0.4, 0.4)
		var largo := rng.randf_range(2.0, 3.4)
		var ini := cima - Vector3(0, rng.randf_range(0.5, 1.8), 0)
		var codo := ini + Vector3(cos(a), 0.25, sin(a)) * largo * 0.6
		var fin := codo + Vector3(cos(a) * 0.4, 1.0, sin(a) * 0.4) * largo * 0.55
		SelvaC2._tubo(c, [ini, codo, fin], [r0 * 0.6, r0 * 0.45, r0 * 0.3], 6, rng, 0.03)
		# roseta plana de hojas grandes en la punta
		SelvaC2._racimo(h, fin + Vector3(0, 0.25, 0), rng.randf_range(1.5, 2.0), 0.3, rng)
		info["racimos"] += 1
		radio_copa = maxf(radio_copa, Vector2(fin.x, fin.z).length() + 1.8)
	info["altura"] = alto + 1.5
	info["radio_copa"] = radio_copa


## Árbol inclinado: se construye inclinado hacia +X local; al colocarlo se gira para que se incline
## hacia donde haga falta (por ejemplo, sobre el camino).
static func _inclinado(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var largo := rng.randf_range(10.0, 13.0)
	var r0 := rng.randf_range(0.3, 0.4)
	var pts := []
	var radios := []
	for i in 10:
		var t := float(i) / 9.0
		# sube recto y luego se curva hacia +X
		var x := pow(t, 1.6) * largo * 0.62
		var y := -0.3 + sin(t * PI * 0.5) * largo * 0.72
		pts.append(Vector3(x, y, sin(t * 3.0) * 0.3))
		radios.append(r0 * (1.0 - 0.55 * t) + r0 * 0.8 * exp(-y * 1.6))
	SelvaC2._tubo(c, pts, radios, 9, rng, 0.06)
	for k in 3:
		var a := rng.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		raiz(c, d * r0, d, 0.9, rng.randf_range(1.5, 2.5), r0 * 0.5, rng)
	var cima: Vector3 = pts[9]
	var radio_copa := 0.0
	for k in rng.randi_range(4, 5):
		var a := rng.randf_range(-1.6, 1.6)
		var ini: Vector3 = pts[rng.randi_range(6, 9)]
		var fin := ini + Vector3(cos(a) * 1.0 + 1.2, rng.randf_range(0.6, 2.0), sin(a) * 2.2) * rng.randf_range(1.2, 2.0)
		_rama(c, h, ini, fin, r0 * 0.3, rng.randf_range(1.5, 2.1), 0.6, rng, info)
		radio_copa = maxf(radio_copa, Vector2(fin.x, fin.z).length() + 2.0)
		if rng.randf() < 0.6:
			SelvaC2._liana(c, fin, rng.randf_range(2.5, 5.0), rng)
	SelvaC2._racimo(h, cima + Vector3(0.6, 1.0, 0), 2.0, 0.6, rng)
	info["racimos"] += 1
	info["altura"] = cima.y + 3.0
	info["radio_copa"] = radio_copa


## Liana entre dos puntos: curva colgante (catenaria aproximada).
static func liana_puente(a: Vector3, b: Vector3, caida: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	var rad := []
	for i in 9:
		var t := float(i) / 8.0
		pts.append(a.lerp(b, t) + Vector3(0, -caida * 4.0 * t * (1.0 - t), 0))
		rad.append(0.05)
	SelvaC2._tubo(st, pts, rad, 5, rng, 0.0)
	return st.commit()


## Malla de luciérnagas: n puntos (tarjetas que el shader orienta a cámara).
static func luciernagas(centros: Array, n: int, semilla: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var c: Vector3 = centros[i % centros.size()]
		var p := c + Vector3(rng.randf_range(-3.5, 3.5), rng.randf_range(0.3, 2.6), rng.randf_range(-3.5, 3.5))
		# las seis esquinas comparten fase: si no, cada vértice volaría por su lado
		var fase := Color(rng.randf(), rng.randf(), 0.0)
		for e in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			st.set_color(fase)
			st.set_uv(e)
			st.add_vertex(p)
	return st.commit()


static func material_suelo(arboles: Array, rocas: Array) -> ShaderMaterial:
	# mismos parámetros que el suelo C2, más las rocas
	var c2 := SelvaC2.material_suelo(arboles)
	var m := ShaderMaterial.new()
	m.shader = SH_SUELO_C3
	m.resource_name = "anime:suelo_selva_c3"
	for u in SelvaC2.SH_SUELO.get_shader_uniform_list():
		var n := String(u["name"])
		var v = c2.get_shader_parameter(n)
		if v != null:
			m.set_shader_parameter(n, v)
	var datos := []
	for r in rocas.slice(0, 48):
		datos.append(r)
	while datos.size() < 48:
		datos.append(Vector4(9999, 9999, 0.001, 0))
	m.set_shader_parameter("rocas", datos)
	m.set_shader_parameter("n_rocas", mini(rocas.size(), 48))
	return m


static func material_luciernaga() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_LUCIERNAGA
	m.resource_name = "anime:luciernaga"
	return m
