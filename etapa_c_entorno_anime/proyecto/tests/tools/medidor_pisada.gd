class_name MedidorPisada
extends RefCounted
## Mide la pisada del Pollo Amarillo fotograma a fotograma a partir del esqueleto animado: altura de la
## suela de cada bota sobre el suelo (rayo hacia abajo), deslizamiento del pie apoyado, orientación de la
## punta respecto a la dirección del cuerpo, dirección en la que se doblan las rodillas y saltos de
## posición del tobillo. Lo usan la sonda de locomoción (videos de validación) y las pruebas automáticas.

## Puntos de la suela de cada bota en reposo (espacio del esqueleto, metros): talón, metatarso y punta.
## Medidos sobre la malla del modelo en Blender (Blender x, y, z -> Godot x, z, -y).
const SUELA := {
	"L": [Vector3(0.245, 0.0, -0.012), Vector3(0.355, 0.0, 0.22), Vector3(0.392, 0.0, 0.297)],
	"R": [Vector3(-0.178, 0.0, -0.158), Vector3(-0.351, 0.0, 0.026), Vector3(-0.409, 0.0, 0.087)],
}
const CONTACTO := 0.015

var jugador: CinematicPlayer
var skel: Skeleton3D
var huesos := {}
var muestras: Array = []
var _prev := {}


func _init(p: CinematicPlayer) -> void:
	jugador = p
	skel = _buscar_esqueleto(p)
	for s in ["L", "R"]:
		huesos[s] = [skel.find_bone("thigh." + s), skel.find_bone("shin." + s), skel.find_bone("foot." + s)]


static func _buscar_esqueleto(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esqueleto(c)
		if r:
			return r
	return null


func _suelo(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.0, 0), p - Vector3(0, 2.0, 0), 1)
	q.exclude = [jugador.get_rid()]
	var r := jugador.get_world_3d().direct_space_state.intersect_ray(q)
	return (r["position"] as Vector3).y if r else 0.0


## Toma una muestra del fotograma actual. 'etiqueta' agrupa las muestras (caminar, correr, transición...).
func muestra(etiqueta: String, dt: float) -> Dictionary:
	var xf := skel.global_transform
	var adelante := jugador.get_facing()
	var m := {"t": etiqueta, "dt": dt, "vel": Vector2(jugador.velocity.x, jugador.velocity.z).length(),
		"anim": jugador.visual.current}
	for s in ["L", "R"]:
		var ib: Array = huesos[s]
		var pie_def := skel.get_bone_global_pose(ib[2]) * skel.get_bone_global_rest(ib[2]).affine_inverse()
		var pts: Array = []
		var alto := INF
		var altos: Array = []
		for p in SUELA[s]:
			var w: Vector3 = xf * (pie_def * p)
			pts.append(w)
			var h := w.y - _suelo(w)
			altos.append(h)
			alto = minf(alto, h)
		var cadera: Vector3 = xf * skel.get_bone_global_pose(ib[0]).origin
		var rodilla: Vector3 = xf * skel.get_bone_global_pose(ib[1]).origin
		var tobillo: Vector3 = xf * skel.get_bone_global_pose(ib[2]).origin
		# rodilla: flexión y hacia dónde apunta respecto a la recta cadera-tobillo
		var flex := 180.0 - rad_to_deg((cadera - rodilla).angle_to(tobillo - rodilla))
		var eje := (tobillo - cadera).normalized()
		var fuera := (rodilla - cadera) - eje * (rodilla - cadera).dot(eje)
		var dir_rodilla := 0.0
		if fuera.length() > 0.004:
			var f2 := adelante - eje * adelante.dot(eje)
			dir_rodilla = rad_to_deg(fuera.angle_to(f2))
		var punta: Vector3 = pts[2] - pts[0]
		punta.y = 0
		var yaw := rad_to_deg(Vector2(adelante.x, adelante.z).angle_to(Vector2(punta.x, punta.z)))
		# hacia fuera positivo (el lado izquierdo del personaje es +x en su espacio local)
		if s == "L":
			yaw = -yaw
		# deslizamiento: media de los puntos de la suela apoyados en este fotograma y en el anterior
		var desliz := -1.0
		var apoyo := alto < CONTACTO
		if apoyo and _prev.has(s):
			var suma := 0.0
			var n := 0
			for k in pts.size():
				if altos[k] < CONTACTO and _prev[s]["altos"][k] < CONTACTO:
					var d: Vector3 = pts[k] - _prev[s]["pts"][k]
					suma += Vector2(d.x, d.z).length() / maxf(dt, 1e-4)
					n += 1
			if n > 0:
				desliz = suma / n
		var salto := 0.0
		if _prev.has(s):
			salto = (tobillo - _prev[s]["tobillo"] - jugador.velocity * dt).length() / maxf(dt, 1e-4)
		m[s] = {"alto": alto, "apoyo": apoyo, "desliz": desliz, "flex": flex, "dir_rodilla": dir_rodilla,
			"yaw": yaw, "vel_tobillo": salto}
		_prev[s] = {"pts": pts, "altos": altos, "tobillo": tobillo}
	muestras.append(m)
	return m


func reiniciar() -> void:
	muestras.clear()
	_prev.clear()


## Resumen por etiqueta: deslizamiento medio del pie apoyado (m/s y % de la velocidad), hundimiento y
## flotación de la suela, fotogramas sin ningún pie en el suelo, rodillas que no apuntan al frente,
## orientación de la punta y el mayor salto de velocidad del tobillo.
func resumen(etiqueta := "") -> Dictionary:
	var sel := muestras.filter(func(m): return etiqueta == "" or m["t"] == etiqueta)
	if sel.is_empty():
		return {}
	var n := sel.size()
	var desliz := 0.0
	var n_desliz := 0
	var vel := 0.0
	var min_alto := INF
	var max_bajo := 0.0
	var sin_apoyo := 0
	var rodilla_mal := 0
	var n_rod := 0
	var max_flex := 0.0
	var yaw_ap := 0.0
	var n_yaw := 0
	var max_yaw := 0.0
	var max_vt := 0.0
	var hundido := 0
	for m in sel:
		vel += m["vel"]
		var algun := false
		var bajo_min := INF
		for s in ["L", "R"]:
			var d: Dictionary = m[s]
			min_alto = minf(min_alto, d["alto"])
			bajo_min = minf(bajo_min, d["alto"])
			if d["alto"] < -0.02:
				hundido += 1
			if d["apoyo"]:
				algun = true
				if d["desliz"] >= 0.0:
					desliz += d["desliz"]
					n_desliz += 1
				yaw_ap += absf(d["yaw"])
				n_yaw += 1
				max_yaw = maxf(max_yaw, absf(d["yaw"]))
			max_flex = maxf(max_flex, d["flex"])
			if d["flex"] > 12.0:
				n_rod += 1
				if d["dir_rodilla"] > 50.0:
					rodilla_mal += 1
			max_vt = maxf(max_vt, d["vel_tobillo"])
		if not algun:
			sin_apoyo += 1
		max_bajo = maxf(max_bajo, bajo_min)
	var v := vel / n
	var ds := desliz / maxi(n_desliz, 1)
	return {
		"muestras": n,
		"velocidad_media": snappedf(v, 0.01),
		"desliz_pie_apoyado_ms": snappedf(ds, 0.001),
		"desliz_pct_velocidad": snappedf(100.0 * ds / maxf(v, 0.01), 0.1),
		"suela_min_m": snappedf(min_alto, 0.001),
		"pct_suela_hundida_2cm": snappedf(100.0 * hundido / (2.0 * n), 0.1),
		"pie_mas_bajo_max_m": snappedf(max_bajo, 0.001),
		"pct_sin_pie_en_suelo": snappedf(100.0 * sin_apoyo / n, 0.1),
		"pct_rodilla_no_al_frente": snappedf(100.0 * rodilla_mal / maxi(n_rod, 1), 0.1),
		"flexion_rodilla_max": snappedf(max_flex, 0.1),
		"punta_apoyada_desvio_medio": snappedf(yaw_ap / maxi(n_yaw, 1), 0.1),
		"punta_apoyada_desvio_max": snappedf(max_yaw, 0.1),
		"vel_tobillo_max_ms": snappedf(max_vt, 0.01),
	}
