extends Node3D

# Puerta del tamaño del marco.
# Cerrada = bloquea el paso. Abierta = se puede pasar.
# Tecla E cerca de la puerta para abrir/cerrar.

@export var open_angle: float = -95.0
@export var speed: float = 4.5
@export var interact_distance: float = 2

var _open: bool = false
var _target_rot: float = 0.0
var _player: Node3D = null
var _key_was_pressed: bool = false

@onready var body: StaticBody3D = $Body

func _ready() -> void:
	# Busca al jugador y deja la puerta cerrada al iniciar.
	_player = get_tree().get_first_node_in_group("jugador") as Node3D
	_open = false
	_target_rot = 0.0
	if body != null:
		body.rotation.y = 0.0
	_set_collision(true)  # cerrada = colision activa

func _process(delta: float) -> void:
	# Actualiza la referencia si el jugador aparece mas tarde.
	if _player == null:
		_player = get_tree().get_first_node_in_group("jugador") as Node3D
		if _player == null:
			return

	var dist: float = global_position.distance_to(_player.global_position)
	var can_interact: bool = dist < interact_distance
	var e_pressed: bool = Input.is_key_pressed(KEY_E)

	# Alterna la puerta con E solo una vez por pulsacion mientras esta cerca.
	if can_interact and e_pressed and not _key_was_pressed:
		_open = not _open
		if _open:
			_target_rot = deg_to_rad(open_angle)
			_set_collision(false)
		else:
			_target_rot = 0.0
			_set_collision(true)

	_key_was_pressed = e_pressed

	# Interpola suavemente la rotacion hasta el angulo objetivo.
	if body != null:
		body.rotation.y = lerp_angle(body.rotation.y, _target_rot, delta * speed)

func _set_collision(enabled: bool) -> void:
	# Activa o desactiva la colision segun el estado de la puerta.
	if body == null:
		return
	body.set_collision_layer_value(1, enabled)
	body.set_collision_mask_value(1, enabled)
	# Alternativa robusta: desactivar el shape
	# for child in body.get_children():
	# 	if child is CollisionShape3D:
	# 		(child as CollisionShape3D).disabled = not enabled
