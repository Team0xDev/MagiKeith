# Este nodo administra el cambio entre la cámara de la casa y la del jugador.
extends Node

# Referencias y estado global de la escena y la pausa.
# Guarda una referencia a la cámara de la casa de la escena actual.
var _house_camera: Camera3D
var paused: bool = false
var pause_menu: Control
var enemy_counter: int = 0
var enemy_needed: int = 0
var mision_completa: bool = false
var player: Node

signal completar_mision

func registrar_enemigo_derrotado() -> void:
	enemy_counter += 1
	print(enemy_counter)
	if enemy_counter >= enemy_needed:
		mision_completa = true
	if mision_completa:
		completar_mision.emit("Mision completa!") 
		await get_tree().create_timer(4.0).timeout
		completar_mision.emit("Fin de la demo!\nGracias por jugar :)")

# Se ejecuta cuando el nodo entra al árbol de la escena.
func _ready() -> void:
	# El mismo script también está en la raíz de la escena; solo el autoload debe gestionar las cámaras.
	if self != get_node_or_null("/root/GameManager"):
		return

	process_mode = Node.PROCESS_MODE_ALWAYS

	# Espera a que cambie la escena para buscar y conectar sus áreas.
	get_tree().scene_changed.connect(_on_scene_changed)
	# Procesa la escena inicial después de que sus nodos estén disponibles.
	_on_scene_changed.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and pause_menu != null:
		pauseMenu()

# Busca la cámara de la casa y conecta las áreas de entrada y salida de la escena cargada.
func _on_scene_changed() -> void:
	player = get_tree().get_first_node_in_group("jugador")
	var scene := get_tree().current_scene
	enemy_needed = get_tree().get_nodes_in_group("enemigos").size()
	var world_limit := scene.get_node_or_null("LimiteMundo") as Area3D
	if world_limit:
		world_limit.body_entered.connect(_on_world_limit_body_entered)
	print(enemy_needed)
	# No hay nada que buscar si no existe una escena activa.
	if scene == null:
		return

	paused = false
	get_tree().paused = false
	pause_menu = scene.find_child("MenuDePausa", true, false) as Control
	if pause_menu != null:
		pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		pause_menu.hide()

	# Obtiene la cámara de la casa mediante su ruta dentro de la escena.
	_house_camera = scene.get_node_or_null("Grupo 2 - Especificos/Casa/CamaraCasa") as Camera3D
	# Si esta escena no tiene cámara de casa, no hay que conectar áreas.
	if _house_camera == null:
		return

	# Busca el área que contiene la colisión del interior.
	var interior_area := _house_camera.get_node_or_null("Area1") as Area3D
	# Conecta la entrada al área interior solo si la señal aún no está conectada.
	if interior_area != null and not interior_area.body_entered.is_connected(_on_interior_body_entered):
		interior_area.body_entered.connect(_on_interior_body_entered)
	# Conecta la salida del área interior solo si la señal aún no está conectada.
	if interior_area != null and not interior_area.body_exited.is_connected(_on_interior_body_exited):
		interior_area.body_exited.connect(_on_interior_body_exited)

# Se activa cuando un cuerpo entra en el área interior.
func _on_interior_body_entered(body: Node3D) -> void:
	# Cambia a la cámara de la casa únicamente cuando entra el jugador.
	if body.is_in_group("jugador") and _house_camera != null:
		_house_camera.make_current()

# Se activa cuando un cuerpo sale del área interior.
func _on_interior_body_exited(body: Node3D) -> void:
	# Ignora cualquier cuerpo que no pertenezca al grupo del jugador.
	if not body.is_in_group("jugador"):
		return

	# La cámara del jugador es hija directa del nodo del personaje.
	var player_camera := body.get_node_or_null("Camera3D") as Camera3D
	# Activa la cámara del jugador solo si existe y no es ya la cámara activa.
	if player_camera != null and get_viewport().get_camera_3d() != player_camera:
		player_camera.make_current()
		
func pauseMenu():
	# Cambia el estado de pausa y muestra u oculta el menu correspondiente.
	paused = !paused
	get_tree().paused = paused
	pause_menu.visible = paused

func _on_world_limit_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		completar_mision.emit("Whoops.")
		await get_tree().create_timer(3).timeout
		enemy_counter = 0
		mision_completa = false
		get_tree().reload_current_scene()
