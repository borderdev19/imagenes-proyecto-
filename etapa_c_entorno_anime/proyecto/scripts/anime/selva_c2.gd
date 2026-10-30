class_name SelvaC2
extends RefCounted
## Etapa C del estilo anime, revisión C2: piezas del entorno selvático creadas en memoria.
## - Árboles por especie (ceiba emergente, árbol de copa redonda, árbol joven): tronco con raíces,
##   ramas, racimos de hojas en capas y lianas. Cada árbol es una malla con dos superficies:
##   0 = corteza y lianas, 1 = racimos de hojas.
## - Rocas facetadas: icosfera deformada y recortada por planos (caras planas y aristas naturales),
##   con la base aplanada y hundida en el suelo.
## - Suelo con más resolución cerca del centro y el camino un poco hundido.
## Ningún recurso original se modifica.

const SH_COPA := preload("res://assets/materials/anime/anime_copa.gdshader")
const SH_SUELO := preload("res://assets/materials/anime/anime_suelo_selva.gdshader")
const TEX_RACIMO := "res://assets/anime/selva_c2/racimo_hojas.png"

enum Especie { CEIBA, REDONDA, JOVEN }

## Camino: x(z) = x0 + A·sin(f·z + fase) + 0.4·A·sin(2.3·f·z + 1.7), ancho w. Igual que en el shader.
const CAMINO := Vector4(3.0, 0.07, 0.4, 2.6)
const CAMINO_X0 := 0.0
const CAMINO_Z_FIN := -90.0


static func camino_x(z: float) -> float:
	return CAMINO_X0 + CAMINO.x * sin(CAMINO.y * z + CAMINO.z) + 0.4 * CAMINO.x * sin(2.3 * CAMINO.y * z + 1.7)


## Distancia horizontal al eje del camino (INF pasado el final del camino).
static func distancia_camino(p: Vector3) -> float:
	if p.z < CAMINO_Z_FIN:
		return INF
	return absf(p.x - camino_x(p.z))


# ------------------------------------------------------------------ árboles
## Devuelve {mesh, altura, radio_copa, racimos (número)}.
static func arbol(especie: int, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var corteza := SurfaceTool.new()
	corteza.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hojas := SurfaceTool.new()
	hojas.begin(Mesh.PRIMITIVE_TRIANGLES)
	var info := {"racimos": 0, "altura": 0.0, "radio_copa": 0.0}
	match especie:
		Especie.CEIBA:
			_ceiba(corteza, hojas, rng, info)
		Especie.REDONDA:
			_redonda(corteza, hojas, rng, info)
		_:
			_joven(corteza, hojas, rng, info)
	var mesh := corteza.commit()
	hojas.commit(mesh)
	info["mesh"] = mesh
	return info


static func _tronco_pts(rng: RandomNumberGenerator, alto: float, segmentos: int, curva: float) -> Array:
	var pts := []
	var fase := rng.randf() * TAU
	var lean := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * curva
	for i in segmentos + 1:
		var t := float(i) / float(segmentos)
		var y := -0.3 + (alto + 0.3) * t
		pts.append(Vector3(sin(t * 2.6 + fase) * curva * 0.35 + lean.x * t * t, y, cos(t * 2.1 + fase) * curva * 0.35 + lean.y * t * t))
	return pts


## Ceiba emergente: tronco alto y recto, raíces tabulares, copa en sombrilla con capas.
static func _ceiba(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(16.0, 22.0)
	var r0 := rng.randf_range(0.5, 0.7)
	var pts := _tronco_pts(rng, alto, 9, 0.6)
	var radios := []
	for i in pts.size():
		var t := float(i) / float(pts.size() - 1)
		radios.append(r0 * (1.0 - 0.5 * t) + r0 * 0.9 * exp(-(pts[i] as Vector3).y * 1.4))
	_tubo(c, pts, radios, 12, rng, 0.05)
	# raíces tabulares
	var n_raices := rng.randi_range(4, 6)
	for k in n_raices:
		var a := TAU * float(k) / float(n_raices) + rng.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		var largo := rng.randf_range(1.8, 2.8)
		_tubo(c, [d * r0 * 0.6 + Vector3(0, 2.4, 0), d * (r0 + largo * 0.45) + Vector3(0, 0.9, 0), d * (r0 + largo) + Vector3(0, -0.2, 0)],
			[r0 * 0.42, r0 * 0.3, 0.05], 6, rng, 0.08)
	var cima: Vector3 = pts[pts.size() - 1]
	var n_ramas := rng.randi_range(5, 7)
	var radio_copa := 0.0
	for k in n_ramas:
		var a := TAU * float(k) / float(n_ramas) + rng.randf_range(-0.35, 0.35)
		var dir := Vector3(cos(a), rng.randf_range(0.18, 0.42), sin(a)).normalized()
		var largo := rng.randf_range(4.5, 7.5)
		var ini := cima + Vector3(0, -rng.randf_range(0.3, 1.8), 0)
		var mid := ini + dir * largo * 0.5 + Vector3(0, 0.7, 0)
		var fin := ini + dir * largo + Vector3(0, rng.randf_range(0.4, 1.4), 0)
		_tubo(c, [ini, mid, fin], [r0 * 0.42, r0 * 0.25, 0.07], 7, rng, 0.06)
		_racimo(h, fin + Vector3(0, 0.6, 0), rng.randf_range(2.2, 3.0), 0.5, rng)
		_racimo(h, mid + Vector3(0, 0.9, 0), rng.randf_range(1.6, 2.2), 0.55, rng)
		_racimo(h, fin + Vector3(rng.randf_range(-1.5, 1.5), 0.2, rng.randf_range(-1.5, 1.5)), rng.randf_range(1.3, 1.8), 0.55, rng)
		info["racimos"] += 3
		radio_copa = maxf(radio_copa, Vector2(fin.x, fin.z).length() + 2.5)
		if rng.randf() < 0.5:
			_liana(c, fin, rng.randf_range(3.0, 7.0), rng)
	# capa superior y una capa baja que rompe la silueta
	_racimo(h, cima + Vector3(0, 1.8, 0), rng.randf_range(2.4, 3.0), 0.5, rng)
	for k in rng.randi_range(2, 3):
		var a := rng.randf() * TAU
		var y := alto * rng.randf_range(0.62, 0.75)
		var ini := Vector3(pts[int(pts.size() * 0.7)].x, y, pts[int(pts.size() * 0.7)].z)
		var fin := ini + Vector3(cos(a), 0.35, sin(a)) * rng.randf_range(2.0, 3.2)
		_tubo(c, [ini, fin], [r0 * 0.22, 0.05], 6, rng, 0.05)
		_racimo(h, fin, rng.randf_range(1.3, 1.9), 0.6, rng)
		info["racimos"] += 1
	info["racimos"] += 1
	info["altura"] = alto + 3.0
	info["radio_copa"] = radio_copa


## Árbol de copa redonda: tronco medio que se abre en ramas; copa de racimos agrupados.
static func _redonda(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(4.0, 6.5)
	var r0 := rng.randf_range(0.28, 0.4)
	var pts := _tronco_pts(rng, alto, 6, 0.5)
	var radios := []
	for i in pts.size():
		var t := float(i) / float(pts.size() - 1)
		radios.append(r0 * (1.0 - 0.35 * t) + r0 * 0.7 * exp(-(pts[i] as Vector3).y * 2.0))
	_tubo(c, pts, radios, 10, rng, 0.06)
	var cima: Vector3 = pts[pts.size() - 1]
	var n_ramas := rng.randi_range(3, 5)
	var radio_copa := 0.0
	var alto_max := alto
	for k in n_ramas:
		var a := TAU * float(k) / float(n_ramas) + rng.randf_range(-0.5, 0.5)
		var dir := Vector3(cos(a), rng.randf_range(0.6, 1.2), sin(a)).normalized()
		var largo := rng.randf_range(2.6, 4.6)
		var ini := cima + Vector3(0, -rng.randf_range(0.0, 0.8), 0)
		var mid := ini + dir * largo * 0.55 + Vector3(dir.x, 0, dir.z) * 0.4
		var fin := ini + dir * largo
		_tubo(c, [ini, mid, fin], [r0 * 0.62, r0 * 0.38, 0.06], 7, rng, 0.06)
		var r := rng.randf_range(1.7, 2.5)
		_racimo(h, fin + Vector3(0, 0.4, 0), r, 0.82, rng)
		for s in rng.randi_range(1, 3):
			var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.5), rng.randf_range(-1, 1)).normalized() * r * rng.randf_range(0.7, 1.0)
			_racimo(h, fin + off, r * rng.randf_range(0.55, 0.8), 0.85, rng)
			info["racimos"] += 1
		info["racimos"] += 1
		radio_copa = maxf(radio_copa, Vector2(fin.x, fin.z).length() + r)
		alto_max = maxf(alto_max, fin.y + r)
		if rng.randf() < 0.35:
			_liana(c, fin, rng.randf_range(2.0, 4.5), rng)
	_racimo(h, cima + Vector3(0, 2.0, 0), rng.randf_range(1.8, 2.4), 0.85, rng)
	info["racimos"] += 1
	info["altura"] = alto_max
	info["radio_copa"] = radio_copa


## Árbol joven: tronco fino y algo inclinado, racimos apilados que se estrechan hacia arriba.
static func _joven(c: SurfaceTool, h: SurfaceTool, rng: RandomNumberGenerator, info: Dictionary) -> void:
	var alto := rng.randf_range(6.0, 9.5)
	var r0 := rng.randf_range(0.14, 0.2)
	var pts := _tronco_pts(rng, alto, 6, 0.9)
	var radios := []
	for i in pts.size():
		radios.append(r0 * (1.0 - 0.55 * float(i) / float(pts.size() - 1)) + r0 * 0.5 * exp(-(pts[i] as Vector3).y * 3.0))
	_tubo(c, pts, radios, 7, rng, 0.05)
	var n := rng.randi_range(5, 7)
	for k in n:
		var t := float(k) / float(n - 1)
		var i := int(lerpf(0.45, 1.0, t) * (pts.size() - 1))
		var eje: Vector3 = pts[i]
		var y := lerpf(alto * 0.45, alto + 0.6, t)
		var off := Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.9, 0.9)) * (1.0 - t * 0.6)
		var centro := Vector3(eje.x, y, eje.z) + off
		if off.length() > 0.35:
			_tubo(c, [Vector3(eje.x, y - 0.5, eje.z), centro], [r0 * 0.4, 0.03], 5, rng, 0.04)
		_racimo(h, centro, lerpf(1.6, 0.8, t) * rng.randf_range(0.85, 1.15), 0.8, rng)
		info["racimos"] += 1
	info["altura"] = alto + 1.4
	info["radio_copa"] = 1.8


## Racimo de hojas: tarjetas repartidas en un elipsoide; las normales salen del centro del racimo
## (el racimo se ilumina como un volumen) con un poco de la orientación propia de cada tarjeta.
static func _racimo(st: SurfaceTool, c: Vector3, radio: float, aplastar: float, rng: RandomNumberGenerator) -> void:
	var n := int(9 + radio * 7.0)
	var tono := rng.randf()
	var viento := clampf(Vector2(c.x, c.z).length() / 7.0 + 0.25, 0.2, 1.0)
	for i in n:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.55, 1.0), rng.randf_range(-1, 1))
		if d.length() < 0.05:
			d = Vector3.UP
		d = d.normalized()
		var pos := c + Vector3(d.x, d.y * aplastar, d.z) * radio * rng.randf_range(0.3, 0.72)
		var fuera := (pos - c).normalized() if (pos - c).length() > 0.01 else Vector3.UP
		var nc := (fuera + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.2, 0.6), rng.randf_range(-0.6, 0.6))).normalized()
		var t := nc.cross(Vector3.UP if absf(nc.y) < 0.9 else Vector3.RIGHT).normalized().rotated(nc, rng.randf() * TAU)
		var b := nc.cross(t).normalized()
		var s := radio * rng.randf_range(0.55, 0.78)
		var celda := rng.randi() % 4
		var uv0 := Vector2(celda % 2, celda / 2) * 0.5
		var esquinas := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		var vs := []
		for e: Vector2 in esquinas:
			var v: Vector3 = pos + t * e.x * s + b * e.y * s
			var nv := (((v - c) / maxf(radio, 0.01)).normalized() * 0.85 + nc * 0.15).normalized()
			vs.append([v, nv, uv0 + (e + Vector2.ONE) * 0.25])
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color(viento, tono, 0.0))
			st.set_normal(vs[k][1])
			st.set_uv(vs[k][2])
			st.add_vertex(vs[k][0])


## Masa continua de copas en el horizonte: un anillo de racimos grandes entre 'r0' y 'r1' metros
## alrededor de 'centro', a varias alturas, para que entre los troncos lejanos no se vea el cielo ni el
## final del suelo. Con la niebla se lee como selva lejana.
static func muro_lejano(semilla: int, centro: Vector3, r0: float, r1: float, n: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var ang := float(i) / float(n) * TAU + rng.randf_range(-0.02, 0.02)
		var r := rng.randf_range(r0, r1)
		var radio := rng.randf_range(7.0, 12.0) * r / r0
		var alto := rng.randf_range(0.2, 1.0) * (16.0 if rng.randf() < 0.75 else 26.0) * r / r0 + radio * 0.4
		_racimo(st, centro + Vector3(sin(ang) * r, alto, -cos(ang) * r), radio, 0.75, rng)
		# racimo bajo para tapar el suelo al pie
		_racimo(st, centro + Vector3(sin(ang) * (r - 4.0), radio * 0.45, -cos(ang) * (r - 4.0)), radio * 0.8, 0.6, rng)
	return st.commit()


## Liana colgante: curva que cae desde 'ini' con un leve balanceo.
static func _liana(st: SurfaceTool, ini: Vector3, largo: float, rng: RandomNumberGenerator) -> void:
	var pts := []
	var radios := []
	var deriva := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
	for i in 6:
		var t := float(i) / 5.0
		pts.append(ini + Vector3(0, -largo * t, 0) + deriva * sin(t * PI))
		radios.append(lerpf(0.05, 0.025, t))
	_tubo(st, pts, radios, 4, rng, 0.0)


## Tubo a lo largo de una polilínea con transporte paralelo del marco. Normales explícitas hacia
## fuera; los triángulos se orientan para la cara frontal de Godot (horaria vista desde fuera).
static func _tubo(st: SurfaceTool, pts: Array, radios: Array, lados: int, rng: RandomNumberGenerator, rugosidad: float) -> void:
	var anillos := []
	var lado := Vector3.ZERO
	for i in pts.size():
		var p: Vector3 = pts[i]
		var t: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		if i == 0:
			lado = t.cross(Vector3.UP if absf(t.y) < 0.95 else Vector3.RIGHT).normalized()
		else:
			lado = (lado - t * lado.dot(t)).normalized()
		var arriba := t.cross(lado).normalized()
		var anillo := []
		for k in lados:
			var a := TAU * float(k) / float(lados)
			var dir := lado * cos(a) + arriba * sin(a)
			var r: float = float(radios[i]) * (1.0 + rng.randf_range(-rugosidad, rugosidad))
			# oclusión al pie del tronco (canal G del color, como en anime_entorno)
			anillo.append([p + dir * r, dir, clampf(0.7 + p.y * 0.3, 0.7, 1.0)])
		anillos.append(anillo)
	for i in anillos.size() - 1:
		for k in lados:
			var k2 := (k + 1) % lados
			_tri_n(st, anillos[i][k], anillos[i + 1][k], anillos[i + 1][k2])
			_tri_n(st, anillos[i][k], anillos[i + 1][k2], anillos[i][k2])


static func _tri_n(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var n: Vector3 = (a[1] as Vector3) + (b[1] as Vector3) + (c[1] as Vector3)
	if ((b[0] as Vector3) - (a[0] as Vector3)).cross((c[0] as Vector3) - (a[0] as Vector3)).dot(n) > 0.0:
		var tmp := b
		b = c
		c = tmp
	for v in [a, b, c]:
		st.set_color(Color(0.0, float(v[2]), 0.0))
		st.set_normal(v[1])
		st.add_vertex(v[0])


# ------------------------------------------------------------------ rocas
## Roca facetada de semiejes 'tam'. Icosfera deformada con ruido suave y recortada por 'planos'
## planos (caras planas grandes) y por la base; queda hundida un 12 % en el suelo.
## Normales: 70 % de la cara + 30 % suaves (facetas visibles pero sin aspecto de polígono).
static func roca(semilla: int, tam: Vector3, planos := 5) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 1.3
	var ico := _icosfera(1)
	var vs: Array = ico[0]
	var caras: Array = ico[1]
	for i in vs.size():
		var d: Vector3 = vs[i]
		var r := 1.0 + nz.get_noise_3d(d.x * 1.2, d.y * 1.2, d.z * 1.2) * 0.16
		vs[i] = Vector3(d.x * tam.x, d.y * tam.y, d.z * tam.z) * r
	for k in planos:
		var n := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.0), rng.randf_range(-1, 1)).normalized()
		var soporte := Vector3(n.x * tam.x, n.y * tam.y, n.z * tam.z).length()
		var dcorte := soporte * rng.randf_range(0.62, 0.86)
		for i in vs.size():
			var s: float = (vs[i] as Vector3).dot(n)
			if s > dcorte:
				vs[i] = (vs[i] as Vector3) - n * (s - dcorte)
	var base := -tam.y * 0.35
	for i in vs.size():
		if (vs[i] as Vector3).y < base:
			vs[i] = Vector3(vs[i].x, base, vs[i].z)
	var subir := -base - tam.y * 0.12
	for i in vs.size():
		vs[i] = (vs[i] as Vector3) + Vector3(0, subir, 0)
	var centro := Vector3(0, subir - tam.y * 0.1, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in caras:
		var a: Vector3 = vs[f[0]]
		var b: Vector3 = vs[f[1]]
		var c: Vector3 = vs[f[2]]
		var fuera := (a + b + c) / 3.0 - centro
		var fn := (b - a).cross(c - a)
		if fn.length() < 1e-7:
			continue
		fn = fn.normalized()
		if fn.dot(fuera) < 0.0:
			fn = -fn
		# orden horario visto desde fuera (cara frontal de Godot)
		if (b - a).cross(c - a).dot(fuera) > 0.0:
			var t := b
			b = c
			c = t
		for v: Vector3 in [a, b, c]:
			var sn := (v - centro).normalized()
			st.set_normal((fn * 0.95 + sn * 0.05).normalized())
			st.set_color(Color(0.0, clampf(0.75 + v.y / maxf(tam.y, 0.01) * 0.25, 0.75, 1.0), 0.0))
			st.add_vertex(v)
	return st.commit()


## Icosfera unitaria subdividida 's' veces: [vértices, caras].
static func _icosfera(s: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var vs := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
		Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in vs.size():
		vs[i] = (vs[i] as Vector3).normalized()
	var caras := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for _k in s:
		var medios := {}
		var nuevas := []
		for f in caras:
			var m := []
			for e in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
				var clave := "%d_%d" % [mini(e[0], e[1]), maxi(e[0], e[1])]
				if not medios.has(clave):
					vs.append(((vs[e[0]] as Vector3) + (vs[e[1]] as Vector3)).normalized())
					medios[clave] = vs.size() - 1
				m.append(medios[clave])
			nuevas.append([f[0], m[0], m[2]])
			nuevas.append([f[1], m[1], m[0]])
			nuevas.append([f[2], m[2], m[1]])
			nuevas.append([m[0], m[1], m[2]])
		caras = nuevas
	return [vs, caras]


# ------------------------------------------------------------------ suelo
## Suelo de 'lado' metros con 'res' celdas por lado; las celdas son más pequeñas en el centro
## (unos 0,75 m) y crecen hacia el borde. Relieve suave y el camino hundido unos centímetros.
static func malla_suelo(lado: float, res: int, semilla: int) -> ArrayMesh:
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 0.03
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mitad := lado * 0.5
	var coord := func(i: int) -> float:
		var u := float(i) / float(res) * 2.0 - 1.0
		return mitad * (0.25 * u + 0.75 * u * u * u)
	for i in res:
		for j in res:
			for k in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				var x: float = coord.call(k[0])
				var z: float = coord.call(k[1])
				var y := nz.get_noise_2d(x, z) * 0.35
				var dc := distancia_camino(Vector3(x, 0, z))
				if dc < 3.0:
					y -= 0.08 * (1.0 - smoothstep(1.0, 3.0, dc))
				st.set_uv(Vector2(x, z) * 0.1)
				st.add_vertex(Vector3(x, y, z))
	st.generate_normals()
	return st.commit()


## Altura del suelo en (x, z): la misma fórmula que malla_suelo, para apoyar objetos.
static func altura_suelo(x: float, z: float, semilla: int) -> float:
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 0.03
	var y := nz.get_noise_2d(x, z) * 0.35
	var dc := distancia_camino(Vector3(x, 0, z))
	if dc < 3.0:
		y -= 0.08 * (1.0 - smoothstep(1.0, 3.0, dc))
	return y


# ------------------------------------------------------------------ materiales
static func material_copa(hoja: Color, luz: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_COPA
	m.resource_name = "anime:copa_c2"
	m.set_shader_parameter("albedo_tex", load(TEX_RACIMO))
	# los vec3 'source_color' reciben un Vector3 sin convertir: se pasan ya en lineal
	var h := hoja.srgb_to_linear()
	var l := luz.srgb_to_linear()
	m.set_shader_parameter("color_hoja", Vector3(h.r, h.g, h.b))
	m.set_shader_parameter("color_luz", Vector3(l.r, l.g, l.b))
	var sh := Color(0.24, 0.32, 0.5)
	m.set_shader_parameter("sombra_color", Vector3(sh.r, sh.g, sh.b))
	m.set_shader_parameter("sombra_fuerza", 0.55)
	m.set_shader_parameter("bandas", 3)
	m.set_shader_parameter("umbral_sombra", 0.0)
	m.set_shader_parameter("umbral_luz", 0.5)
	m.set_shader_parameter("tono_medio", 0.8)
	m.set_shader_parameter("suavizado", 0.04)
	m.set_shader_parameter("translucidez", 0.25)
	m.set_shader_parameter("mascara_contorno", EstiloAnime.MASCARA_FOLLAJE)
	return m


static func material_suelo(arboles: Array) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_SUELO
	m.resource_name = "anime:suelo_selva"
	m.set_shader_parameter("camino", CAMINO)
	m.set_shader_parameter("camino_x0", CAMINO_X0)
	m.set_shader_parameter("camino_z_fin", CAMINO_Z_FIN)
	var datos := []
	for a in arboles.slice(0, 64):
		datos.append(a)
	while datos.size() < 64:
		datos.append(Vector4(9999, 9999, 0.001, 0))
	m.set_shader_parameter("arboles", datos)
	m.set_shader_parameter("n_arboles", mini(arboles.size(), 64))
	var sh := EstiloAnime.SOMBRA
	m.set_shader_parameter("sombra_color", Vector3(sh.r, sh.g, sh.b))
	m.set_shader_parameter("sombra_fuerza", 0.55)
	m.set_shader_parameter("bandas", 2)
	m.set_shader_parameter("umbral_sombra", 0.05)
	m.set_shader_parameter("suavizado", 0.03)
	m.set_shader_parameter("mascara_contorno", EstiloAnime.MASCARA_SOLIDO)
	return m
