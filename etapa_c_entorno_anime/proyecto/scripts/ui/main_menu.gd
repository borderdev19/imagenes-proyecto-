class_name MainMenu
extends Node3D
## Menú inicial: escenario del claro (fondo prerenderizado + modelos 3D animados) con
## las opciones Jugar, Controles, Opciones (gráficos y pantalla) y Salir.

var stage: CombatStage
var _controls: PanelContainer
var _options: OptionsPanel
var _menu_box: VBoxContainer
var _play_btn: Button


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	stage = CombatStage.new()
	add_child(stage)
	var hero: ChickenVisual = load("res://scenes/characters/PolloAmarillo.tscn").instantiate()
	var enemy: ChickenVisual = load("res://scenes/characters/PolloNegro.tscn").instantiate()
	stage.place(hero, stage.hero_mark, stage.enemy_mark)
	stage.place(enemy, stage.enemy_mark, stage.hero_mark)
	stage.hero_ref = hero
	stage.enemy_ref = enemy
	stage.menu_orbit = true
	hero.play("battle_idle", 0.0)
	enemy.play("special_charge", 0.0)
	var aura := CombatVFX.new()
	add_child(aura)
	aura.charge_aura(hero, Color(1.0, 0.5, 0.1), 0.0)
	_build_ui()
	AudioManager.stop_ambient()
	AudioManager.play_music("music_title", -10.0)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10    # por encima del filtro pictórico (capa 5): el texto del menú no se pinta
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.get_theme()
	layer.add_child(root)
	var grad := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.78))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 256
	gt.height = 16
	grad.texture = gt
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.anchor_bottom = 1.0
	grad.offset_right = 1100
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grad)
	var v := VBoxContainer.new()
	v.position = Vector2(110, 150)
	v.add_theme_constant_override("separation", 12)
	root.add_child(v)
	_menu_box = v
	var t1 := UITheme.label("PLUMA ÍGNEA", 118, Color(1, 0.86, 0.38), UITheme.FONT_TITLE)
	t1.add_theme_constant_override("outline_size", 16)
	t1.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.02))
	v.add_child(t1)
	var t2 := UITheme.label("Crónicas de la Selva Esmeralda", 40, Color(0.95, 0.95, 0.9), UITheme.FONT_TITLE_700)
	v.add_child(t2)
	var t3 := UITheme.label("Prototipo jugable · RPG 3D por turnos", 24, UITheme.C_MUTED)
	v.add_child(t3)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 50)
	v.add_child(sp)
	_play_btn = _btn("Jugar", v, _on_play)
	_btn("Controles", v, func():
		_options.visible = false
		_controls.visible = not _controls.visible)
	_btn("Opciones", v, func():
		_controls.visible = false
		_options.visible = not _options.visible
		if _options.visible:
			_options.focus_first())
	_btn("Laboratorio anime", v, func():
		if not SceneRouter.is_busy():
			SceneRouter.change_scene(PruebaAnime.ESCENA))
	var quit := _btn("Salir", v, func(): get_tree().quit())
	quit.visible = not OS.has_feature("web")
	_controls = ControlsPanel.build()
	_controls.position = Vector2(1080, 160)
	_controls.visible = false
	root.add_child(_controls)
	_options = OptionsPanel.new()
	_options.position = Vector2(1080, 160)
	_options.visible = false
	root.add_child(_options)
	var foot := UITheme.label("Godot 4.7 · Modelos y fondo creados en Blender · Proyecto original", 20, Color(1, 1, 1, 0.65))
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_left = 110
	foot.offset_top = -60
	root.add_child(foot)
	_play_btn.grab_focus()


func _btn(text: String, parent: Node, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 74)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func():
		AudioManager.play("ui_click", -6.0)
		cb.call())
	parent.add_child(b)
	return b


func _on_play() -> void:
	if SceneRouter.is_busy():
		return
	GameState.new_game()
	GameState.exploration_scene = GameState.SCENE_MUNDO
	SceneRouter.change_scene(GameState.SCENE_MUNDO, 0.6, 0.8)

