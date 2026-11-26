extends Node
# Distribuye pasto aleatorio y evita colocar instancias sobre zonas excluidas.

const GRASS_SEED := 2006
const EXCLUSION_MARGIN := 0.75
const MIN_GRASS_SCALE := 0.7
const MAX_GRASS_SCALE := 1.35
const GRASS_HEIGHT := 0.02
const MAX_ATTEMPTS_PER_INSTANCE := 10

var grass_count: int = 3000

func _ready() -> void:
	# Regenera el pasto cuando cambia de escena.
	get_tree().scene_changed.connect(_on_scene_changed)
	if get_tree().current_scene != null:
		_on_scene_changed.call_deferred()

func _on_scene_changed() -> void:
	# Espera un frame para generar el pasto sobre los nodos ya cargados.
	var scene := get_tree().current_scene
	if scene == null:
		return

	# La escena cambia de inmediato, pero sus nodos tardan un frame en estar listos.
	call_deferred("_generate_grass", scene)

func _generate_grass(scene: Node) -> void:
	# Busca el nodo MultiMesh y detiene la generacion si no existe.
	if scene == null or scene != get_tree().current_scene:
		return

	var grass: MultiMeshInstance3D
	for node in scene.get_tree().get_nodes_in_group("grass"):
		if node is MultiMeshInstance3D:
			grass = node
			break

	if grass == null:
		return

	var multimesh := grass.multimesh
	if multimesh == null:
		push_error("ForestSpawner: el nodo de pasto no tiene un MultiMesh asignado.")
		return

	var ground := scene.find_child("Suelo", true, false) as MeshInstance3D
	if ground == null or ground.mesh == null:
		push_error("ForestSpawner: no se encontro el mesh 'Suelo' en la escena actual.")
		return

	var exclusions: Array[AABB] = []
	# Reune los limites de edificios, agua, montanas y pilares.
	_collect_exclusion_bounds(scene.find_child("Casa", true, false), exclusions)
	_collect_exclusion_bounds(scene.find_child("Rio", true, false), exclusions)
	_collect_exclusion_bounds(scene.find_child("Montanas", true, false), exclusions)
	_collect_exclusion_bounds(scene.find_child("Montanas*", true, false), exclusions)
	for pilar in scene.find_children("Pilar*", "VisualInstance3D", true, false):
		_collect_exclusion_bounds(pilar, exclusions)

	var rng := RandomNumberGenerator.new()
	rng.seed = GRASS_SEED
	var ground_bounds := _transform_aabb(ground.get_aabb(), ground.global_transform)

	multimesh.instance_count = grass_count
	# Coloca instancias aleatorias hasta alcanzar el objetivo o agotar intentos.
	var placed := 0
	var attempts := 0
	var max_attempts := grass_count * MAX_ATTEMPTS_PER_INSTANCE

	while placed < grass_count and attempts < max_attempts:
		attempts += 1
		var x := rng.randf_range(ground_bounds.position.x, ground_bounds.end.x)
		var z := rng.randf_range(ground_bounds.position.z, ground_bounds.end.z)

		if _is_excluded(x, z, exclusions):
			continue

		var scale_value := rng.randf_range(MIN_GRASS_SCALE, MAX_GRASS_SCALE)
		var world_transform := Transform3D(
			Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			.scaled(Vector3.ONE * scale_value),
			Vector3(x, GRASS_HEIGHT, z)
		)

		var local_transform := grass.global_transform.affine_inverse() * world_transform
		multimesh.set_instance_transform(placed, local_transform)
		placed += 1

	multimesh.visible_instance_count = placed
	print("Pasto generado: ", placed)

func _collect_exclusion_bounds(root: Node, exclusions: Array[AABB]) -> void:
	# Convierte los limites visuales de un nodo a coordenadas del mundo.
	if root == null:
		return

	if root is VisualInstance3D:
		var local_bounds: AABB = root.get_aabb()
		if local_bounds.size != Vector3.ZERO:
			exclusions.append(
				_transform_aabb(local_bounds, root.global_transform).grow(EXCLUSION_MARGIN)
			)

	for child in root.get_children():
		_collect_exclusion_bounds(child, exclusions)

func _transform_aabb(local_bounds: AABB, world_transform: Transform3D) -> AABB:
	return world_transform * local_bounds

func _is_excluded(x: float, z: float, exclusions: Array[AABB]) -> bool:
	# Comprueba si una posicion horizontal coincide con una zona excluida.
	for bounds in exclusions:
		if (
			x >= bounds.position.x
			and x <= bounds.end.x
			and z >= bounds.position.z
			and z <= bounds.end.z
		):
			return true
	return false
