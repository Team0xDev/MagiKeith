extends CharacterBody3D

# Parametros exportables de movimiento, ataque y vida.
@export var speed: float = 0.5
@export var dañoBase: float = 2
@export var vidaBase: float =  20.0
@export var indice_enemigo: int = -1

@onready var timerAtk1: Timer = $TimerAtk1
@onready var timerAtk2: Timer = $TimerAtk2

# Estado de deteccion, persecucion y enfriamiento del enemigo.
var player: CharacterBody3D
var aggro: bool = false
var cooldownAtk1: bool = false
var cooldownAtk2: bool = true

signal daniar(quien: Node, cuanto: int)

func _ready() -> void:
	# Inicializa al jugador como nulo y conecta el dano con el personaje.
	player = null #Player empieza siendo nulo
	var playerG = get_tree().get_nodes_in_group("jugador")
	daniar.connect(playerG[0]._on_enemigo_daniar)
	

func _process(_delta: float) -> void:
	if vidaBase > 0:
		# Persigue al jugador y mantiene la orientacion hacia el.
		if player:
			var direction = global_position.direction_to(player.global_position) #Declara la variable direccion con el valor de la posicion del jugador

			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if direction != Vector3.ZERO:
				var target_position = Vector3(player.global_position.x, global_position.y, player.global_position.z) 
				look_at(target_position, Vector3.UP) #Fija la posicion a donde tiene que ir
		if aggro:
			atacar()
		move_and_slide() #Mover al enemigo respetando colisiones
	# Cuando no queda vida, elimina al enemigo y registra su derrota.
	if vidaBase <= 0:
		morir()

func atacar():
	# Emitimos el dano una sola vez y esperamos a que termine el enfriamiento.
	if !cooldownAtk1:
		cooldownAtk1 = true
		daniar.emit(player,dañoBase)
		timerAtk1.start()
		await timerAtk1.timeout
		cooldownAtk1 = false



func _on_areadeteccion_body_entered(body: Node3D) -> void:
	# Empieza la persecucion al detectar al jugador.
	if body.is_in_group("jugador"):
			player = body #Declara player como body para que empiece a calcular donde se encuentra el jugador a partir de aca


func _on_areadeteccion_body_exited(body: Node3D) -> void:
	# Detiene la persecucion cuando el jugador sale del area.
	if body == player:
		player = null
		velocity = Vector3.ZERO

func _on_areaataque_body_entered(body: Node3D) -> void:
	# Activa el ataque al entrar el jugador en el area cercana.
	if body.is_in_group("jugador"):
		aggro = true

func _on_areaataque_body_exited(body: Node3D) -> void:
	# Desactiva el ataque al abandonar el area cercana.
	if body == player:
		aggro = false #Vuelve aggro falso para que deje de atacar al jugador

func _on_player_daniarobjetivo(quien: Node3D, cuanto: int) -> void:
	# Recibe dano solo si el objetivo coincide con este enemigo.
	if !quien:
		return
	if quien.get_class() == self.get_class() and quien.name == self.name:
		vidaBase -= cuanto
		print(self.name," recibio ",cuanto," puntos de daño")

func morir():
	print(self.name," murio")
	GameManager.registrar_enemigo_derrotado(indice_enemigo)
	queue_free()
