class_name ChickenVisual
extends Node3D
## Envoltorio del modelo GLB de un pollo: localiza el AnimationPlayer importado,
## configura los bucles y ofrece una API sencilla para reproducir animaciones con mezcla.

signal animation_done(anim: String)

const LOOPING := ["idle", "battle_idle", "walk", "run", "special_charge"]
const CICLOS := ["walk", "run"]
const ANIMS := ["idle", "battle_idle", "walk", "run", "hit", "attack", "defend", "special_charge", "special_cast", "victory", "defeat"]

@export var start_animation := "idle"

var anim_player: AnimationPlayer
var current := ""


func _ready() -> void:
	anim_player = _find_anim_player(self)
	if anim_player == null:
		push_error("ChickenVisual: no se encontró AnimationPlayer en " + name)
		return
	for a in LOOPING:
		if anim_player.has_animation(a):
			anim_player.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	if not anim_player.animation_finished.is_connected(_on_finished):
		anim_player.animation_finished.connect(_on_finished)
	_set_shadows(self)
	play(start_animation, 0.0)


func _set_shadows(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c in n.get_children():
		_set_shadows(c)


func _find_anim_player(n: Node) -> AnimationPlayer:
	for c in n.get_children():
		if c is AnimationPlayer:
			return c
		var r := _find_anim_player(c)
		if r:
			return r
	return null


func has_anim(anim: String) -> bool:
	return anim_player != null and anim_player.has_animation(anim)


func play(anim: String, blend := 0.15, speed := 1.0) -> void:
	if anim_player == null or not anim_player.has_animation(anim):
		push_warning("ChickenVisual: animación inexistente " + anim)
		return
	if current == anim and anim_player.is_playing() and LOOPING.has(anim):
		anim_player.speed_scale = speed
		return
	current = anim
	anim_player.speed_scale = speed
	anim_player.play(anim, blend)


## Ciclos de desplazamiento (walk/run): al cambiar de uno a otro el nuevo empieza en la misma fase
## normalizada (los dos apoyan el pie izquierdo en la fase 0), así la mezcla no cruza las piernas.
func play_ciclo(anim: String, blend := 0.2, speed := 1.0) -> void:
	var fase := -1.0
	if current in CICLOS and anim in CICLOS and current != anim and anim_player and anim_player.is_playing():
		fase = fase_ciclo()
	play(anim, blend, speed)
	if fase >= 0.0:
		anim_player.seek(fase * anim_length(anim), false)


## Fase normalizada (0..1) de la animación en curso.
func fase_ciclo() -> float:
	if anim_player == null or not anim_player.is_playing():
		return 0.0
	var l := anim_length(anim_player.current_animation)
	return fposmod(anim_player.current_animation_position, l) / l if l > 0.0 else 0.0


func restart(anim: String, blend := 0.1, speed := 1.0) -> void:
	current = ""
	play(anim, blend, speed)
	if anim_player:
		anim_player.seek(0.0, true)


func anim_length(anim: String) -> float:
	if anim_player and anim_player.has_animation(anim):
		return anim_player.get_animation(anim).length
	return 0.0


func play_and_wait(anim: String, blend := 0.1, speed := 1.0) -> void:
	restart(anim, blend, speed)
	var dur := anim_length(anim) / maxf(speed, 0.01)
	await get_tree().create_timer(dur, false).timeout


func _on_finished(anim: StringName) -> void:
	animation_done.emit(String(anim))


## Aplica un tinte de destello (daño) temporal a todos los materiales.
func flash(color := Color(1, 0.3, 0.3), time := 0.18) -> void:
	var meshes: Array = []
	_collect_meshes(self, meshes)
	for m in meshes:
		var mi := m as MeshInstance3D
		var ov := StandardMaterial3D.new()
		ov.albedo_color = Color(color.r, color.g, color.b, 0.55)
		ov.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ov.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ov.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mi.material_overlay = ov
	await get_tree().create_timer(time, false).timeout
	for m in meshes:
		if is_instance_valid(m):
			(m as MeshInstance3D).material_overlay = null


func _collect_meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)
