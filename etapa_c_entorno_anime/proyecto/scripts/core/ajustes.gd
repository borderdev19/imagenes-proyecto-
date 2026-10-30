extends Node
## Opciones de PC (autoload «Ajustes»): modo de ventana, resolución, VSync, calidad gráfica,
## cantidad de partículas y distancia de vegetación. Se guardan en user://ajustes.cfg.
## En el iPhone (Compatibility) la calidad se limita a lo que ese renderizador soporta: SSAO, SSR,
## niebla volumétrica y SSIL solo existen en Forward+, así que allí se ignoran sin degradar el PC.

signal cambiado

const ARCHIVO := "user://ajustes.cfg"
const MODOS := ["Ventana", "Pantalla completa", "Pantalla completa exclusiva"]
const RESOLUCIONES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const CALIDADES := ["Baja", "Media", "Alta", "Ultra"]
const PARTICULAS := ["Pocas", "Normales", "Muchas"]
const PARTICULAS_MULT := [0.45, 1.0, 1.5]
## Estilo visual (Etapa B): el pictórico v13 sigue siendo el de fábrica mientras el anime está a prueba.
const ESTILOS := ["Pictórico (v13)", "Anime (prueba)"]
const ESTILO_PICTORICO := 0
const ESTILO_ANIME := 1

## Perfil de cada calidad: sombras, efectos de pantalla, antialiasing, escala de render y vegetación.
const PERFILES := [
	{"sombra": 2048, "suave": 0, "ssao": false, "ssr": false, "niebla": false, "ssil": false, "msaa": Viewport.MSAA_DISABLED, "escala": 0.77, "veg": 0.6, "dof": false},
	{"sombra": 4096, "suave": 1, "ssao": true, "ssr": false, "niebla": true, "ssil": false, "msaa": Viewport.MSAA_2X, "escala": 1.0, "veg": 0.85, "dof": true},
	{"sombra": 4096, "suave": 2, "ssao": true, "ssr": true, "niebla": true, "ssil": false, "msaa": Viewport.MSAA_2X, "escala": 1.0, "veg": 1.0, "dof": true},
	{"sombra": 8192, "suave": 3, "ssao": true, "ssr": true, "niebla": true, "ssil": true, "msaa": Viewport.MSAA_4X, "escala": 1.0, "veg": 1.35, "dof": true},
]

var modo_ventana := 0
var resolucion := 1          ## índice de RESOLUCIONES (solo en modo ventana)
var vsync := true
var calidad := 2             ## Alta por defecto: lo probado en todas las versiones anteriores
var particulas_nivel := 1
var estilo := ESTILO_PICTORICO
## Contornos del estilo anime (casco invertido en personajes y líneas de pantalla en el escenario).
var contornos := true
var _entornos: Array[WeakRef] = []
## La ventana solo se toca si el jugador ya eligió algo (archivo guardado o cambio en Opciones):
## así la primera ejecución respeta project.godot y las opciones de línea de comandos (--resolution).
var _ventana_elegida := false
## false en pruebas automáticas: no se lee ni se escribe el archivo y no se toca la ventana.
var persistir := true


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		persistir = false
	cargar()
	aplicar()


func cargar() -> void:
	if not persistir:
		return
	var cf := ConfigFile.new()
	if cf.load(ARCHIVO) != OK:
		return
	_ventana_elegida = true
	modo_ventana = clampi(cf.get_value("pantalla", "modo", modo_ventana), 0, MODOS.size() - 1)
	resolucion = clampi(cf.get_value("pantalla", "resolucion", resolucion), 0, RESOLUCIONES.size() - 1)
	vsync = cf.get_value("pantalla", "vsync", vsync)
	calidad = clampi(cf.get_value("graficos", "calidad", calidad), 0, CALIDADES.size() - 1)
	particulas_nivel = clampi(cf.get_value("graficos", "particulas", particulas_nivel), 0, PARTICULAS.size() - 1)
	estilo = clampi(cf.get_value("graficos", "estilo", estilo), 0, ESTILOS.size() - 1)
	contornos = cf.get_value("graficos", "contornos", contornos)
	GameState.painterly_filter = cf.get_value("graficos", "filtro_pictorico", GameState.painterly_filter)


func guardar() -> void:
	if not persistir:
		return
	var cf := ConfigFile.new()
	cf.set_value("pantalla", "modo", modo_ventana)
	cf.set_value("pantalla", "resolucion", resolucion)
	cf.set_value("pantalla", "vsync", vsync)
	cf.set_value("graficos", "calidad", calidad)
	cf.set_value("graficos", "particulas", particulas_nivel)
	cf.set_value("graficos", "estilo", estilo)
	cf.set_value("graficos", "contornos", contornos)
	cf.set_value("graficos", "filtro_pictorico", GameState.painterly_filter)
	cf.save(ARCHIVO)


## Valores de fábrica (las pruebas los usan para no depender de lo que haya elegido el jugador).
func por_defecto() -> void:
	modo_ventana = 0
	resolucion = 1
	vsync = true
	calidad = 2
	particulas_nivel = 1
	estilo = ESTILO_PICTORICO
	contornos = true
	aplicar()


func es_anime() -> bool:
	return estilo == ESTILO_ANIME


func perfil() -> Dictionary:
	return PERFILES[calidad]


## Multiplicador de partículas (combate y ambiente).
func particulas() -> float:
	return PARTICULAS_MULT[particulas_nivel]


## Multiplicador de la distancia a la que se dibuja la vegetación instanciada.
func vegetacion() -> float:
	return perfil().veg


func set_valor(clave: String, valor: int) -> void:
	match clave:
		"modo_ventana":
			modo_ventana = valor
			_ventana_elegida = true
		"resolucion":
			resolucion = valor
			_ventana_elegida = true
		"vsync":
			vsync = valor != 0
			_ventana_elegida = true
		"calidad": calidad = valor
		"particulas": particulas_nivel = valor
		"estilo": estilo = clampi(valor, 0, ESTILOS.size() - 1)
		"contornos": contornos = valor != 0
	aplicar()
	guardar()


func aplicar() -> void:
	_aplicar_ventana()
	_aplicar_render()
	cambiado.emit()


func _aplicar_ventana() -> void:
	if not persistir or not _ventana_elegida:
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	match modo_ventana:
		0:
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var sz: Vector2i = RESOLUCIONES[resolucion]
			var screen := DisplayServer.screen_get_usable_rect()
			sz = Vector2i(mini(sz.x, screen.size.x), mini(sz.y, screen.size.y))
			DisplayServer.window_set_size(sz)
			DisplayServer.window_set_position(screen.position + (screen.size - sz) / 2)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _aplicar_render() -> void:
	var p := perfil()
	for w in _entornos:
		var env := w.get_ref() as Environment
		if env:
			aplicar_entorno(env)
	RenderingServer.directional_shadow_atlas_set_size(p.sombra, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(p.suave)
	RenderingServer.positional_soft_shadow_filter_set_quality(p.suave)
	var vp := get_viewport()
	vp.msaa_3d = p.msaa
	if CinematicLook.forward_plus():
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if p.escala < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = p.escala
		RenderingServer.environment_set_ssao_quality(
			RenderingServer.ENV_SSAO_QUALITY_ULTRA if calidad == 3 else RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
			calidad == 3, 0.5, 2, 50.0, 300.0)


## Ajusta un Environment ya configurado por CinematicLook a la calidad elegida (solo apaga o enciende
## efectos; los valores artísticos los fija CinematicLook).
func registrar_entorno(env: Environment) -> void:
	_entornos = _entornos.filter(func(w): return w.get_ref() != null)
	_entornos.append(weakref(env))
	aplicar_entorno(env)


func aplicar_entorno(env: Environment) -> void:
	if env == null or not CinematicLook.forward_plus():
		return
	var p := perfil()
	env.ssao_enabled = p.ssao
	env.ssr_enabled = p.ssr and env.get_meta("ssr_base", true)
	env.volumetric_fog_enabled = p.niebla and env.get_meta("niebla_base", true)
	env.ssil_enabled = p.ssil
	if p.ssil:
		env.ssil_radius = 4.0
		env.ssil_intensity = 0.6
