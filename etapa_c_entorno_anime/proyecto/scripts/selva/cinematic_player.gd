class_name CinematicPlayer
extends CharacterBody3D
## Control del Pollo Amarillo para los escenarios de cámara fija.
## Movimiento con peso: aceleración y frenado suaves, giro del cuerpo antes de avanzar en cambios
## bruscos de dirección, inclinación al acelerar y en las curvas, modo de equilibrio en zonas
## estrechas (más lento, balanceo lateral y desplazamiento lateral limitado) y caminatas guiadas
## para las secuencias. Las direcciones son relativas a la cámara activa y se mantienen estables
## en los cortes de plano mientras no se suelte el joystick.

signal interact_pressed
signal step(foot: int)
## se emite al devolver al jugador a un punto seguro tras caer fuera de la zona caminable
signal rescued

## Caminar a 1,7 m/s: con piernas de 0,71 m (cadera) es un paso ligero natural (número de Froude ≈ 0,4).
## A 2,3 m/s cualquier caminata de estas piernas obliga a patinar o a trotar (Froude 0,76 > 0,5).
@export var walk_speed := 1.7
@export var run_speed := 4.4
## Zancada de cada ciclo de animación (metros que avanza el cuerpo en un ciclo completo, dos pasos), la
## misma con la que se generaron walk y run (blender/scripts/locomocion_heroe.py). La animación se
## reproduce a la velocidad que hace coincidir zancada y desplazamiento: el pie apoyado no patina.
@export var walk_stride := 1.1
@export var run_stride := 2.0
## Velocidad a la que se pasa de caminar a correr (y vuelta, con histéresis); entre medias el ciclo se
## mezcla conservando la fase, así el pie que estaba apoyado sigue apoyado.
@export var run_blend_speed := 2.75
@export var balance_speed := 0.95
@export var acceleration := 6.5
@export var deceleration := 9.0
@export var turn_rate := 7.5
@export var gravity := 22.0
## Altura de escalón que se sube sin saltar (piedras, raíces bajas, bordes de tablones).
@export var step_height := 0.32

@onready var pivot: Node3D = $Pivot
@onready var visual: ChickenVisual = $Pivot/Visual

var input_enabled := true
## Base (solo giro Y) de la cámara activa; el control es relativo a la pantalla.
var view_basis := Basis()
var _held_basis := Basis()
var _holding := false
var _last_input := Vector2.ZERO
## Comprueba si una posición está dentro de la zona caminable (la asigna el nivel).
var walk_check: Callable
## Datos de la rama bajo los pies: estrechez 0..1 y tangente (los asigna el nivel).
var narrow := 0.0
var path_tangent := Vector3.ZERO
var forced_anim := ""
var facing_yaw := 0.0

var _yaw_vel := 0.0
var _lean := Vector2.ZERO
var _sway_t := 0.0
var _wobble := 0.0
var _wobble_cd := 2.0
var _auto_target := Vector3.INF
var _auto_speed := 2.0
var _last_valid := Vector3.ZERO
var _stranded_time := 0.0
var _air_time := 0.0
var _safe_trail: Array[Vector3] = []
var _trail_t := 0.0
var _corriendo_anim := false
var _fase_prev := -1.0


func _ready() -> void:
	floor_max_angle = deg_to_rad(50)
	floor_snap_length = 0.5
	_last_valid = global_position
	facing_yaw = pivot.rotation.y


func set_input_enabled(v: bool) -> void:
	input_enabled = v
	if not v:
		velocity.x = 0
		velocity.z = 0


## Cambio de cámara: conservar la dirección de control anterior mientras se mantenga el joystick.
func on_camera_cut(new_basis: Basis) -> void:
	if _last_input.length() > 0.2:
		_held_basis = view_basis
		_holding = true
	view_basis = new_basis


func place(p: Vector3, yaw: float) -> void:
	global_position = p
	_last_valid = p
	_safe_trail.clear()
	velocity = Vector3.ZERO
	facing_yaw = yaw
	pivot.rotation = Vector3(0, yaw, 0)


func face_towards(point: Vector3, time := 0.35) -> void:
	var d := point - global_position
	d.y = 0
	if d.length() < 0.01:
		return
	var target := atan2(d.x, d.z)
	var t := create_tween()
	var from := facing_yaw
	t.tween_method(func(v: float):
		facing_yaw = v
		pivot.rotation.y = v, from, from + wrapf(target - from, -PI, PI), time)
	await t.finished


## Caminata guiada (secuencias): avanza hacia 'target' con la misma física y animación.
func walk_to(target: Vector3, speed := 1.8, timeout := 8.0) -> void:
	_auto_target = target
	_auto_speed = speed
	var t := 0.0
	while _auto_target != Vector3.INF and t < timeout:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	_auto_target = Vector3.INF


func get_move_input() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


func _physics_process(delta: float) -> void:
	var iv := get_move_input()
	# estabilidad del control tras un corte de cámara
	if _holding:
		if iv.length() < 0.2 or (_last_input.length() > 0.2 and iv.normalized().dot(_last_input.normalized()) < 0.7):
			_holding = false
	_last_input = iv
	var b := _held_basis if _holding else view_basis
	var fwd := -b.z
	fwd.y = 0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var right := b.x
	right.y = 0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var dir := right * iv.x + fwd * (-iv.y)
	var auto := _auto_target != Vector3.INF
	if auto:
		var to := _auto_target - global_position
		to.y = 0
		if to.length() < 0.12:
			_auto_target = Vector3.INF
			dir = Vector3.ZERO
		else:
			dir = to.normalized() * clampf(to.length() / 0.6, 0.35, 1.0)
	var mag := minf(dir.length(), 1.0)
	if mag > 0.001:
		dir = dir.normalized()
	# en zonas estrechas: el desplazamiento lateral se limita y se sigue la rama
	if narrow > 0.01 and path_tangent != Vector3.ZERO and mag > 0.0 and not auto:
		var side := path_tangent.cross(Vector3.UP)
		var along := dir.dot(path_tangent)
		var lat := dir.dot(side) * (1.0 - 0.8 * narrow)
		var nd := path_tangent * along + side * lat
		if nd.length() > 0.01:
			mag *= clampf(nd.length() * 1.15, 0.0, 1.0)
			dir = nd.normalized()
	var running := input_enabled and Input.is_action_pressed("run") and narrow < 0.3 and not auto
	var max_speed := run_speed if running else walk_speed
	if auto:
		max_speed = _auto_speed
	max_speed = lerpf(max_speed, balance_speed, narrow)
	# giro del cuerpo: los cambios bruscos se resuelven girando antes de avanzar
	var desired_yaw := facing_yaw
	if mag > 0.05:
		desired_yaw = atan2(dir.x, dir.z)
	var diff := wrapf(desired_yaw - facing_yaw, -PI, PI)
	var turn_speed := turn_rate * (0.55 if narrow > 0.5 else 1.0)
	var step_yaw := clampf(diff, -turn_speed * delta, turn_speed * delta)
	facing_yaw = wrapf(facing_yaw + step_yaw, -PI, PI)
	_yaw_vel = lerpf(_yaw_vel, step_yaw / maxf(delta, 1e-4), clampf(delta * 8.0, 0, 1))
	var align := clampf(cos(diff), 0.0, 1.0)
	align = align * align
	var target_vel := dir * max_speed * mag * align
	# el avance real sigue la orientación del cuerpo (sensación de peso)
	var body_fwd := Vector3(sin(facing_yaw), 0, cos(facing_yaw))
	if mag > 0.05:
		target_vel = body_fwd * target_vel.length()
	# momento de equilibrio: pequeña pausa y balanceo amplio en la parte más estrecha
	if narrow > 0.55 and target_vel.length() > 0.2 and not auto:
		_wobble_cd -= delta
		if _wobble_cd <= 0.0:
			_wobble = 1.0
			_wobble_cd = randf_range(2.6, 4.2)
	_wobble = maxf(0.0, _wobble - delta * 1.4)
	target_vel *= 1.0 - 0.75 * _wobble
	var hv := Vector3(velocity.x, 0, velocity.z)
	var rate := acceleration if target_vel.length() > hv.length() else deceleration
	var old_hv := hv
	hv = hv.move_toward(target_vel, rate * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if is_on_floor():
		velocity.y = -0.2
	else:
		velocity.y -= gravity * delta
	var before := global_position
	move_and_slide()
	_step_up(hv, delta, before)
	# límites: no salir de la zona caminable (se desliza a lo largo del borde)
	if walk_check.is_valid() and not walk_check.call(global_position):
		var p := global_position
		var try_x := Vector3(p.x, p.y, before.z)
		var try_z := Vector3(before.x, p.y, p.z)
		if walk_check.call(try_x):
			global_position = try_x
			velocity.z = 0
		elif walk_check.call(try_z):
			global_position = try_z
			velocity.x = 0
		else:
			global_position = Vector3(before.x, p.y, before.z)
			velocity.x = 0
			velocity.z = 0
	if is_on_floor() and (not walk_check.is_valid() or walk_check.call(global_position)):
		_last_valid = global_position
	# rastro de puntos seguros (el más antiguo, ~0,75 s atrás, queda lejos del borde por el que se cayó)
	_trail_t += delta
	if _trail_t > 0.25:
		_trail_t = 0.0
		_safe_trail.append(_last_valid)
		if _safe_trail.size() > 3:
			_safe_trail.pop_front()
	# red de seguridad: si cae fuera de la zona caminable (un hueco, un borde), vuelve al último punto
	# válido en vez de quedarse atrapado donde ningún movimiento es posible
	var stranded: bool = walk_check.is_valid() and not walk_check.call(global_position)
	# también si queda encajado en el aire entre dos colisiones (sin suelo durante más de 1,5 s)
	_stranded_time = _stranded_time + delta if stranded else 0.0
	_air_time = 0.0 if is_on_floor() else _air_time + delta
	if _air_time > 1.5:
		_stranded_time = 1.0
	if global_position.y < _last_valid.y - 2.5 or _stranded_time > 0.3:
		var back: Vector3 = _safe_trail[0] if not _safe_trail.is_empty() else _last_valid
		global_position = back + Vector3(0, 0.3, 0)
		_last_valid = back
		_safe_trail.clear()
		velocity = Vector3.ZERO
		_stranded_time = 0.0
		_air_time = 0.0
		rescued.emit()
	_update_visual(delta, old_hv, hv)


## Subida de escalones: si un borde bajo frena el avance, se prueba el mismo paso un poco más arriba.
## También sirve cuando el personaje se queda trabado sin avanzar en un pliegue del terreno (la cápsula
## choca con la arista entre dos triángulos del suelo y move_and_slide no recorre nada).
func _step_up(hv: Vector3, delta: float, before: Vector3) -> void:
	if step_height <= 0.0 or hv.length() < 0.2:
		return
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	var snagged := is_on_floor() and moved < hv.length() * delta * 0.15
	if snagged and not is_on_wall():
		# se despega un poco del suelo y repite el paso (la gravedad lo vuelve a asentar)
		global_position = before + Vector3(0, 0.05, 0)
		move_and_slide()
		return
	if not is_on_wall():
		return
	var motion := hv * delta * 1.5
	var up := Vector3(0, step_height, 0)
	var t := global_transform
	if test_move(t, up):
		return
	var raised := t.translated(up)
	if test_move(raised, motion):
		return
	# hay suelo al bajar desde el escalón (no se sube a nada colgado en el aire)
	var landed := raised.translated(motion)
	var col := KinematicCollision3D.new()
	if not test_move(landed, -up * 1.2, col):
		return
	if col.get_normal().y < 0.7:
		return
	global_position = landed.origin + col.get_travel()
	velocity.y = 0.0


func _update_visual(delta: float, old_hv: Vector3, hv: Vector3) -> void:
	pivot.rotation.y = facing_yaw
	var spd := hv.length()
	var accel := (hv.length() - old_hv.length()) / maxf(delta, 1e-4)
	# inclinación hacia delante al acelerar y hacia dentro en las curvas. Es pequeña: el giro de todo el
	# modelo sube o hunde las botas apoyadas (con 9° la punta entraba 5 cm en el suelo). La inclinación de
	# la marcha ya va en las animaciones walk/run (tronco y pelvis), por eso no depende de la velocidad.
	var target_pitch := clampf(accel * 0.012, -0.05, 0.06)
	var target_roll := clampf(-_yaw_vel * spd * 0.02, -0.08, 0.08)
	_sway_t += delta * (2.0 + spd * 0.8)
	target_roll += sin(_sway_t * 1.3) * 0.09 * narrow * (0.4 + minf(spd, 1.0)) + sin(_sway_t * 3.1) * 0.12 * _wobble
	_lean.x = lerpf(_lean.x, target_pitch, clampf(delta * 6.0, 0, 1))
	_lean.y = lerpf(_lean.y, target_roll, clampf(delta * 5.0, 0, 1))
	visual.rotation = Vector3(_lean.x, 0, _lean.y)
	if forced_anim != "":
		visual.play(forced_anim, 0.2)
		return
	if spd < 0.18:
		visual.play("idle", 0.3)
		_corriendo_anim = false
		_fase_prev = -1.0
		return
	if _corriendo_anim:
		_corriendo_anim = spd > run_blend_speed - 0.2
	else:
		_corriendo_anim = spd > run_blend_speed + 0.2
	var anim := "run" if _corriendo_anim else "walk"
	var zancada := run_stride if _corriendo_anim else walk_stride
	var rate := clampf(spd * visual.anim_length(anim) / zancada, 0.25, 3.0)
	visual.play_ciclo(anim, 0.22, rate)
	_footsteps()


## Pisadas sincronizadas con la animación: cada ciclo apoya el pie izquierdo en la fase 0 y el derecho en
## la 0,5 (walk y run se generaron así).
func _footsteps() -> void:
	var f := visual.fase_ciclo()
	if _fase_prev >= 0.0:
		var cruza := (f < _fase_prev) or (_fase_prev < 0.5 and f >= 0.5)
		if cruza:
			step.emit(0 if f < 0.5 else 1)
	_fase_prev = f


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and event.is_action_pressed("interact"):
		interact_pressed.emit()


func get_facing() -> Vector3:
	return Vector3(sin(facing_yaw), 0, cos(facing_yaw))
