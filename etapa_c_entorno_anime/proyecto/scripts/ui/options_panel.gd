class_name OptionsPanel
extends PanelContainer
## Panel de opciones de PC (menú principal y pausa). Cada fila es un botón que recorre sus valores
## (clic, Enter o A del mando; con ← → también se cambia), así funciona igual con ratón, mando y táctil.
## Los cambios se aplican al momento y se guardan en user://ajustes.cfg (ver Ajustes).

const DESCRIPCION_CALIDAD := [
	"Sombras 2048, sin SSAO, reflejos ni niebla volumétrica, render al 77 % con FSR, vegetación cercana.",
	"Sombras 4096, SSAO y niebla volumétrica, sin reflejos de pantalla, MSAA 2x.",
	"Sombras 4096 suaves, SSAO, reflejos de pantalla y niebla volumétrica, MSAA 2x (recomendada).",
	"Sombras 8192, SSAO e iluminación indirecta (SSIL), MSAA 4x, vegetación lejana.",
]

var _rows := {}
var _desc: Label


func _ready() -> void:
	custom_minimum_size = Vector2(760, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(UITheme.label("OPCIONES", 40, UITheme.C_GOLD, UITheme.FONT_TITLE))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var desktop := not OS.has_feature("mobile")
	if desktop:
		_row(grid, "pantalla", "Pantalla")
		_row(grid, "resolucion", "Resolución")
		_row(grid, "vsync", "Sincronía vertical")
	_row(grid, "calidad", "Calidad gráfica")
	_row(grid, "particulas", "Partículas")
	_row(grid, "estilo", "Estilo visual")
	_row(grid, "contornos", "Contornos anime")
	_row(grid, "filtro", "Filtro pictórico")
	_desc = UITheme.label("", 20, UITheme.C_MUTED, UITheme.FONT_BODY_REG)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(700, 0)
	v.add_child(_desc)
	if not CinematicLook.forward_plus():
		var note := UITheme.label("Renderizador Compatibility (iPhone/Xogot): SSAO, reflejos y niebla volumétrica no están disponibles.", 18, UITheme.C_MUTED, UITheme.FONT_BODY_REG)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(700, 0)
		v.add_child(note)
	var hint := UITheme.label("La distancia de la vegetación se aplica al volver a cargar la zona.", 18, UITheme.C_MUTED, UITheme.FONT_BODY_REG)
	v.add_child(hint)
	_refresh()


func _row(grid: GridContainer, key: String, title: String) -> void:
	grid.add_child(UITheme.label(title, 24, Color(1, 0.93, 0.75), UITheme.FONT_BOLD))
	var b := Button.new()
	b.custom_minimum_size = Vector2(380, 54)
	b.pressed.connect(func():
		AudioManager.play("ui_click", -6.0)
		_step(key, 1))
	b.gui_input.connect(func(ev: InputEvent):
		if ev.is_action_pressed("ui_left"):
			_step(key, -1)
			b.accept_event()
		elif ev.is_action_pressed("ui_right"):
			_step(key, 1)
			b.accept_event())
	grid.add_child(b)
	_rows[key] = b


func _step(key: String, dir: int) -> void:
	match key:
		"pantalla": Ajustes.set_valor("modo_ventana", wrapi(Ajustes.modo_ventana + dir, 0, Ajustes.MODOS.size()))
		"resolucion": Ajustes.set_valor("resolucion", wrapi(Ajustes.resolucion + dir, 0, Ajustes.RESOLUCIONES.size()))
		"vsync": Ajustes.set_valor("vsync", 0 if Ajustes.vsync else 1)
		"calidad": Ajustes.set_valor("calidad", wrapi(Ajustes.calidad + dir, 0, Ajustes.CALIDADES.size()))
		"particulas": Ajustes.set_valor("particulas", wrapi(Ajustes.particulas_nivel + dir, 0, Ajustes.PARTICULAS.size()))
		"estilo": Ajustes.set_valor("estilo", wrapi(Ajustes.estilo + dir, 0, Ajustes.ESTILOS.size()))
		"contornos": Ajustes.set_valor("contornos", 0 if Ajustes.contornos else 1)
		"filtro":
			GameState.painterly_filter = not GameState.painterly_filter
			Ajustes.guardar()
	_refresh()


func _refresh() -> void:
	var r: Vector2i = Ajustes.RESOLUCIONES[Ajustes.resolucion]
	var values := {
		"pantalla": Ajustes.MODOS[Ajustes.modo_ventana],
		"resolucion": "%d × %d" % [r.x, r.y] + ("" if Ajustes.modo_ventana == 0 else " (solo en ventana)"),
		"vsync": "Sí" if Ajustes.vsync else "No",
		"calidad": Ajustes.CALIDADES[Ajustes.calidad],
		"particulas": Ajustes.PARTICULAS[Ajustes.particulas_nivel],
		"estilo": Ajustes.ESTILOS[Ajustes.estilo],
		"contornos": "Sí" if Ajustes.contornos else "No",
		"filtro": ("Sí" if GameState.painterly_filter else "No") + (" (solo en pictórico)" if Ajustes.es_anime() else ""),
	}
	for k in _rows:
		(_rows[k] as Button).text = "‹  %s  ›" % values[k]
	_desc.text = DESCRIPCION_CALIDAD[Ajustes.calidad]
	if Ajustes.es_anime():
		_desc.text += "\nEstilo anime en prueba: el mundo conserva sus materiales v13 hasta la Etapa C; la vista completa está en «Laboratorio anime» del menú principal."


func focus_first() -> void:
	if not _rows.is_empty():
		(_rows.values()[0] as Button).grab_focus()
