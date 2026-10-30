extends RefCounted
## Pruebas del sistema de materiales anime (Etapa B): compilación de shaders, fábrica de materiales,
## conservación de los personajes (malla, esqueleto, animaciones), selector de estilo y laboratorio.
## Las ejecuta tests/e2e_director.gd en los modos all, unit y anime.

var results: Array = []

const SHADERS := {
	"res://assets/materials/anime/anime_personaje.gdshader": ["bandas", "sombra_color", "especular_fuerza", "borde_fuerza", "albedo_tex", "tinte", "mascara_contorno"],
	"res://assets/materials/anime/anime_contorno.gdshader": ["grosor_px", "oscurecer", "distancia_fin", "activo"],
	"res://assets/materials/anime/anime_entorno.gdshader": ["bandas", "color_plano", "detalle", "pintado", "musgo", "balanceo_modo", "mascara_contorno"],
	"res://assets/materials/anime/anime_follaje.gdshader": ["bandas", "color_hoja", "viento", "doblar", "normales_esfericas", "centro_copa", "translucidez"],
	"res://assets/materials/anime/anime_contorno_post.gdshader": ["grosor_px", "umbral_profundidad", "umbral_normal", "distancia_fin", "activo"],
}

## Recursos originales de la v13 que la Etapa B no debe tocar (MD5 de la v13 entregada).
const ORIGINALES := {
	"res://assets/materials/mundo/agua_cenote.gdshader": "e4d4a197574173f6fcb70b78977b82cf",
	"res://assets/materials/mundo/cascada.gdshader": "2bd813a32e3f4a178d816e7612fe9373",
	"res://assets/materials/mundo/cielo_mundo.gdshader": "8d146d307e08107c44d2d057450f8b27",
	"res://assets/materials/mundo/hojas_mundo.gdshader": "3016ab4abcd6e9608257205a7d086db8",
	"res://assets/materials/mundo/montana.gdshader": "c77531d2dc3ee942cad6aa09d02eefc8",
	"res://assets/materials/mundo/mundo_pbr.gdshader": "626d25b0892c8254d82224b65e4fc526",
	"res://assets/materials/mundo/planta.gdshader": "e03f06c5a83a006d9176c507d11970e9",
	"res://assets/materials/mundo/terreno.gdshader": "f6fb666afbd98238ecbc9532cb785e2b",
	"res://assets/materials/post/pintura.gdshader": "32a63f641f2caef0caef5527baff2d77",
	"res://assets/characters/pollo_amarillo.glb": "6a8462bd55186262d3b97e50ba86f42b",
	"res://assets/characters/pollo_negro.glb": "38c9b0ca9ae09ead063b23658c2e017c",
	"res://assets/mundo3d/mundo.glb": "1353b6116ddc7538e3c26d0832e4408b",
	"res://assets/mundo3d/biblioteca.glb": "f1d3fe0a189a6420ca29b6cc309c91d6",
	"res://scripts/mundo/materiales_mundo.gd": "6a008c0f2864998204afdae81bc1fe04",
}


func check(name: String, cond: bool, detail := "") -> void:
	results.append({"name": name, "ok": cond, "detail": detail})
	print(("  [OK]   " if cond else "  [FAIL] ") + name + ("" if detail == "" else "  -> " + detail))


func run_all(tree: SceneTree) -> Array:
	print("== Pruebas del estilo anime ==")
	test_shaders()
	test_originales()
	test_fabrica()
	test_personajes(tree)
	test_ajustes(tree)
	return results


## Un shader que no compila no expone uniformes: así se detectan los errores también sin GPU.
func test_shaders() -> void:
	for p in SHADERS:
		var s: Shader = load(p)
		var names: Array = s.get_shader_uniform_list().map(func(u): return String(u["name"])) if s else []
		var faltan: Array = (SHADERS[p] as Array).filter(func(n): return not names.has(n))
		check("Shader anime compila y expone sus parámetros: " + p.get_file(), s != null and faltan.is_empty(), "faltan " + str(faltan))
	var inc := FileAccess.get_file_as_string("res://assets/materials/anime/anime_luz.gdshaderinc")
	check("Iluminación anime común con light() propia (bandas, sombra teñida, especular, borde)",
		inc.contains("void light()") and inc.contains("sombra_color") and inc.contains("especular_tamano") and inc.contains("borde_ancho"))


func test_originales() -> void:
	var cambiados := []
	for p in ORIGINALES:
		if FileAccess.get_md5(p) != ORIGINALES[p]:
			cambiados.append(p.get_file())
	check("Recursos originales v13 intactos (shaders, GLB, materiales del mundo)", cambiados.is_empty(), str(cambiados))


func test_fabrica() -> void:
	var tex := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	var base := StandardMaterial3D.new()
	base.albedo_texture = tex
	base.albedo_color = Color(0.9, 0.5, 0.3)
	base.resource_name = "piel"
	var m := EstiloAnime.material_personaje(base, Color(0.8, 1.0, 1.0))
	check("Material de personaje: conserva textura y color y aplica el tinte de aldeano",
		m.get_shader_parameter("albedo_tex") == tex and (m.get_shader_parameter("color_base") as Color).is_equal_approx(base.albedo_color)
		and (m.get_shader_parameter("tinte") as Vector3).is_equal_approx(Vector3(0.8, 1, 1)))
	check("Material de personaje: el contorno va en next_pass (material_overlay queda libre para el daño)",
		m.next_pass is ShaderMaterial and (m.next_pass as ShaderMaterial).shader == EstiloAnime.SH_CONTORNO)
	var metal := StandardMaterial3D.new()
	metal.metallic = 1.0
	metal.roughness = 0.3
	var mm := EstiloAnime.material_personaje(metal)
	check("Material de personaje: el metal recibe un brillo estilizado más fuerte", float(mm.get_shader_parameter("especular_fuerza")) > float(m.get_shader_parameter("especular_fuerza")))
	var ojo := StandardMaterial3D.new()
	ojo.resource_name = "Ojo_Negro"
	var mo := EstiloAnime.material_personaje(ojo)
	check("Material de personaje: los ojos no llevan contorno y tienen brillo propio", mo.next_pass == null and float(mo.get_shader_parameter("brillo_propio")) > 0.0)
	var e := EstiloAnime.material_entorno({"color": Color(0.5, 0.4, 0.3), "musgo": 0.3})
	var f := EstiloAnime.material_follaje({"color": Color(0.3, 0.6, 0.2), "centro": Vector3(0, 2, 0)})
	check("Materiales separados por familia: personaje, entorno y follaje usan shaders distintos",
		m.shader != e.shader and e.shader != f.shader and m.shader != f.shader)
	check("Máscaras de contorno: sólido < follaje < personaje",
		float(e.get_shader_parameter("mascara_contorno")) < float(f.get_shader_parameter("mascara_contorno")) and float(f.get_shader_parameter("mascara_contorno")) < float(m.get_shader_parameter("mascara_contorno")))


func _contar(n: Node, out: Dictionary) -> void:
	if n is Skeleton3D:
		out["huesos"] = (n as Skeleton3D).get_bone_count()
	if n is AnimationPlayer:
		out["anims"] = (n as AnimationPlayer).get_animation_list().size()
	if n is MeshInstance3D:
		var am := (n as MeshInstance3D).mesh as ArrayMesh
		for i in am.get_surface_count():
			out["tris"] = int(out.get("tris", 0)) + am.surface_get_array_index_len(i) / 3
	for c in n.get_children():
		_contar(c, out)


func test_personajes(tree: SceneTree) -> void:
	for path: String in ["res://scenes/characters/PolloAmarillo.tscn", "res://scenes/characters/PolloNegro.tscn"]:
		var c: Node3D = (load(path) as PackedScene).instantiate()
		tree.root.add_child(c)
		var antes := {}
		_contar(c, antes)
		var mallas: Array = c.find_children("*", "MeshInstance3D", true, false)
		var originales := []
		for mi in mallas:
			for i in (mi as MeshInstance3D).get_surface_override_material_count():
				originales.append((mi as MeshInstance3D).get_active_material(i))
		EstiloAnime.aplicar_a_personaje(c)
		var despues := {}
		_contar(c, despues)
		var todos_anime := true
		for mi in mallas:
			for i in (mi as MeshInstance3D).get_surface_override_material_count():
				var am := (mi as MeshInstance3D).get_active_material(i) as ShaderMaterial
				todos_anime = todos_anime and am != null and am.shader == EstiloAnime.SH_PERSONAJE
		var nombre := path.get_file().get_basename()
		check("%s: todas las superficies pasan a material anime" % nombre, todos_anime)
		check("%s: malla, esqueleto (21 huesos) y 11 animaciones intactos" % nombre,
			antes == despues and int(despues.get("huesos", 0)) == 21 and int(despues.get("anims", 0)) == 11, "%s -> %s" % [antes, despues])
		EstiloAnime.restaurar_personaje(c)
		var vuelta := []
		for mi in mallas:
			for i in (mi as MeshInstance3D).get_surface_override_material_count():
				vuelta.append((mi as MeshInstance3D).get_active_material(i))
		check("%s: vuelve a sus materiales v13 sin pérdidas" % nombre, vuelta == originales)
		c.queue_free()


func test_ajustes(tree: SceneTree) -> void:
	var e0: int = Ajustes.estilo
	var c0: bool = Ajustes.contornos
	Ajustes.por_defecto()
	check("Opciones: el estilo de fábrica sigue siendo el pictórico v13", Ajustes.estilo == Ajustes.ESTILO_PICTORICO and not Ajustes.es_anime() and Ajustes.contornos)
	Ajustes.set_valor("estilo", Ajustes.ESTILO_ANIME)
	Ajustes.set_valor("contornos", 0)
	check("Opciones: selector de estilo anime y contornos", Ajustes.es_anime() and not Ajustes.contornos)
	var look := CinematicLook.new()
	tree.root.add_child(look)
	GameState.painterly_filter = true
	var oculto := not look.is_active()
	Ajustes.set_valor("estilo", Ajustes.ESTILO_PICTORICO)
	var visible := look.is_active()
	check("El filtro pictórico se apaga en el estilo anime y vuelve en el v13", oculto and visible)
	look.queue_free()
	var panel := OptionsPanel.new()
	tree.root.add_child(panel)
	check("Panel de Opciones: filas Estilo visual y Contornos sin perder las anteriores",
		panel._rows.has("estilo") and panel._rows.has("contornos") and panel._rows.has("calidad") and panel._rows.has("particulas") and panel._rows.has("filtro"))
	(panel._rows["estilo"] as Button).pressed.emit()
	check("Panel de Opciones: el botón Estilo cambia el estilo", Ajustes.es_anime())
	panel.queue_free()
	Ajustes.set_valor("estilo", e0)
	Ajustes.set_valor("contornos", 1 if c0 else 0)
