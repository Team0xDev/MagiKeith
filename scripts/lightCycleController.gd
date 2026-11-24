extends Node

# Ciclo dia / noche simple
# Rota el sol y ajusta energia + color de ambiente

@export_range(1.0, 86400.0) var day_length_seconds: float = 240.0
@export var sun_path: NodePath = NodePath("Sol")
@export var moon_path: NodePath = NodePath("Luna")
@export var environment_path: NodePath = NodePath("WorldEnvironment")
@export_range(0.02, 1.0) var update_interval: float = 0.08
# #######
# 0.0: medianoche.
# 0.25: amanecer.
# 0.5: mediodía.
# 0.75: atardecer.
var _time: float = 0.25
# #######
var _update_accumulator: float = 0.0
var sun: DirectionalLight3D = null
var moon: DirectionalLight3D = null
var env: Environment = null

func _ready() -> void:
	# Vigila cambios en el árbol y resuelve las luces de la escena.
	get_tree().tree_changed.connect(_on_tree_changed)
	_resolve_scene_nodes()

func _on_tree_changed() -> void:
	call_deferred("_resolve_scene_nodes")

func _resolve_scene_nodes() -> void:
	# Reinicia y busca nuevamente el sol, la luna y el entorno.
	sun = null
	moon = null
	env = null

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	var sun_node: Node = _resolve_node(scene_root, sun_path, "Sol")
	var moon_node: Node = _resolve_node(scene_root, moon_path, "Luna")
	var environment_node: Node = _resolve_node(scene_root, environment_path, "WorldEnvironment")

	if sun_node is DirectionalLight3D:
		sun = sun_node as DirectionalLight3D
	if moon_node is DirectionalLight3D:
		moon = moon_node as DirectionalLight3D
	var we: Node = environment_node
	if we != null and we is WorldEnvironment:
		env = (we as WorldEnvironment).environment
	_update_sky()

func _resolve_node(scene_root: Node, configured_path: NodePath, fallback_name: String) -> Node:
	# Resuelve un nodo por ruta relativa, ruta absoluta o nombre alternativo.
	if configured_path != NodePath():
		# Relative paths remain useful when the controller is attached locally.
		var direct_node: Node = get_node_or_null(configured_path)
		if direct_node != null:
			return direct_node

		# Absolute and scene-relative paths also need to work with this as an autoload.
		var scene_node: Node = scene_root.get_node_or_null(configured_path)
		if scene_node != null:
			return scene_node

	return _find_node_by_name(scene_root, fallback_name)

func _find_node_by_name(parent: Node, node_name: String) -> Node:
	# Busca recursivamente un nodo por su nombre.
	if parent.name == node_name:
		return parent
	for child in parent.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null

func _process(delta: float) -> void:
	# Avanza la hora del dia y actualiza el cielo a intervalos definidos.
	_time = fmod(_time + delta / day_length_seconds, 1.0)
	_update_accumulator += delta
	if _update_accumulator >= update_interval:
		_update_accumulator = fmod(_update_accumulator, update_interval)
		_update_sky()

func _update_sky() -> void:
	# Rota las luces y ajusta energia, color, niebla y ambiente segun la hora.
	# 0.0 = medianoche, 0.25 = amanecer, 0.5 = mediodia, 0.75 = atardecer
	var angle: float = _time * TAU - PI * 0.25

	if sun == null and moon == null and env == null:
		return

	if sun != null:
		sun.rotation.x = -angle
		var sun_height: float = sin(angle)
		sun.light_energy = clampf(sun_height * 1.4, 0.0, 1.3)
		var night_col := Color(1.0, 0.55, 0.3)
		var day_col := Color(1.0, 0.92, 0.75)
		sun.light_color = day_col.lerp(night_col, clampf(1.0 - sun_height, 0.0, 1.0))
		sun.shadow_enabled = sun.light_energy > 0.15

	if moon != null:
		moon.rotation.x = -angle + PI
		var moon_height: float = sin(angle + PI)
		moon.light_energy = clampf(moon_height * 0.35, 0.0, 0.3)

	if env != null:
		var day_factor: float = clampf(sin(angle) * 1.2, 0.0, 1.0)
		env.ambient_light_energy = lerpf(0.25, 0.7, day_factor)
		var fog_night := Color(0.15, 0.18, 0.28)
		var fog_day := Color(0.45, 0.5, 0.6)
		env.fog_light_color = fog_night.lerp(fog_day, day_factor)
