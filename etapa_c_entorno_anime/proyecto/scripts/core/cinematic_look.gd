class_name CinematicLook
extends CanvasLayer
## Aspecto cinematográfico común a exploración, combate y menú:
## - entorno con claroscuro: oclusión ambiental (SSAO), reflejos de pantalla (SSR), niebla volumétrica,
##   resplandor y temperatura de color (solo en Forward+, el renderizador de PC);
## - profundidad de campo que desenfoca el fondo como en una pintura al óleo;
## - filtro pictórico a pantalla completa (pintura.gdshader): pinceladas, paleta desaturada con acentos,
##   viraje de color, viñeta y grano. Se dibuja por debajo del HUD y se puede desactivar en la pausa.
## En el iPhone (renderizador Compatibility) se aplica lo que existe allí: filtro, niebla normal y resplandor.

const POST_SHADER := preload("res://assets/materials/post/pintura.gdshader")

var _rect: ColorRect
var _mat: ShaderMaterial


static func forward_plus() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


## kind: "prerender" (fondos de Blender con el tono ya horneado), "arena" (escena 3D del combate) o
## "mundo" (mundo 3D en tiempo real: selva algo menos saturada y niebla volumétrica más profunda).
static func setup_environment(env: Environment, kind: String) -> void:
	var fp := forward_plus()
	var real3d := kind != "prerender"
	env.glow_enabled = true
	env.glow_intensity = 0.5 if real3d else 0.35
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# temperatura y contraste: algo más frío y apagado, el filtro pictórico devuelve el calor a las luces
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.97
	env.adjustment_contrast = 1.12 if real3d else 1.06
	env.adjustment_saturation = 0.88 if kind == "mundo" else 1.0
	env.ssao_enabled = fp
	env.ssao_radius = 1.4 if real3d else 0.8
	env.ssao_intensity = 2.6 if real3d else 1.4
	env.ssao_power = 1.6
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.15
	env.ssr_enabled = fp and real3d
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	# en exploración el fondo prerrenderizado ya trae su bruma (y una capa animada propia): solo en la arena
	env.volumetric_fog_enabled = fp and real3d
	if fp:
		env.volumetric_fog_density = {"arena": 0.007, "mundo": 0.009}.get(kind, 0.012)
		env.volumetric_fog_albedo = Color(0.9, 0.93, 0.84)
		env.volumetric_fog_anisotropy = 0.55
		env.volumetric_fog_length = {"arena": 48.0, "mundo": 80.0}.get(kind, 36.0)
		env.volumetric_fog_detail_spread = 2.0
		env.volumetric_fog_gi_inject = 0.0
		env.volumetric_fog_sky_affect = 0.15 if real3d else 0.0
		env.volumetric_fog_ambient_inject = 0.0
	# lo que este tipo de escena permite; Ajustes lo recorta según la calidad elegida en Opciones
	env.set_meta("ssr_base", env.ssr_enabled)
	env.set_meta("niebla_base", env.volumetric_fog_enabled)
	Ajustes.registrar_entorno(env)


## Profundidad de campo: enfoca hasta 'focus' metros y desenfoca suavemente lo que queda detrás.
static func make_camera_attributes(focus: float, blur := 0.08) -> CameraAttributesPractical:
	var ca := CameraAttributesPractical.new()
	set_focus(ca, focus, blur)
	return ca


static func set_focus(ca: CameraAttributesPractical, focus: float, blur := 0.08) -> void:
	if ca == null:
		return
	ca.dof_blur_far_enabled = Ajustes.perfil().dof
	ca.dof_blur_far_distance = maxf(focus, 1.0)
	ca.dof_blur_far_transition = maxf(focus * 1.6, 6.0)
	ca.dof_blur_near_enabled = false
	ca.dof_blur_amount = blur


## Sol principal muy marcado con sombras suaves (penumbra real en Forward+).
static func setup_sun(sun: DirectionalLight3D, energy_scale := 1.15) -> void:
	sun.light_energy *= energy_scale
	sun.light_angular_distance = 1.2
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.92


func _ready() -> void:
	layer = 5
	_rect = ColorRect.new()
	_rect.name = "FiltroPictorico"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = POST_SHADER
	_rect.material = _mat
	add_child(_rect)
	GameState.look_changed.connect(_refresh)
	Ajustes.cambiado.connect(_refresh)
	_refresh()


func _refresh() -> void:
	# el estilo anime necesita bordes limpios: el filtro pictórico solo existe en el estilo v13
	_rect.visible = GameState.painterly_filter and not Ajustes.es_anime()


func set_param(param: String, value) -> void:
	_mat.set_shader_parameter(param, value)


func is_active() -> bool:
	return _rect.visible
