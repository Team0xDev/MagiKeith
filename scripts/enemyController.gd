extends CharacterBody3D

# Parametros exportables
enum ClaseEnemigo { JEFE, MINIJEFE, BASE }

@export var clase: ClaseEnemigo = ClaseEnemigo.BASE

#onready
@onready var timerAtk1: Timer = $TimerAtk1
@onready var timerAtk2: Timer = $TimerAtk2
@onready var rangoDeteccion: CollisionShape3D = $AreaDeteccion/RangoDeteccion
@onready var rangoAtaque: CollisionShape3D = $AreaAtaque/RangoAtaque
@onready var mesh_enemigo: MeshInstance3D = $Capsula
@onready var colision_cuerpo: CollisionShape3D = $ColisionEnemigo
@onready var barra_vida: ProgressBar = $SubViewport/BarraDeVida
@onready var barra_vida_billboard: Sprite3D = $BarraVidaBillboard


var player: CharacterBody3D
var playerPermanente: CharacterBody3D
var colisionPlayer: CollisionShape3D
var aggro: bool = false
var perseguirDano: bool = false
var cooldownAtk1: bool = false
var cooldownAtk2: bool = true

#Modificables de clase
var speed: float
var daño: float
var vidaEnemy: float
var escala_clase: float
var radio_deteccion: float
var escala_atkbox: float


signal daniar(quien: Node, cuanto: int)

func _ready() -> void:
	# Inicializa al jugador como nulo y conecta el dano con el personaje.
	player = null #Player empieza siendo nulo
	playerPermanente = get_tree().get_first_node_in_group("jugador")
	colisionPlayer = playerPermanente.get_node("ColisionGato") as CollisionShape3D
	daniar.connect(playerPermanente._on_enemigo_daniar)
	
	match clase: #Asigna valores segun la clase
		ClaseEnemigo.BASE:
			speed = 1.7
			daño = 5.0
			vidaEnemy = 13
			escala_clase = 1.3
			radio_deteccion = 4
			escala_atkbox = 1.5
		ClaseEnemigo.MINIJEFE:
			speed = 1.5
			daño = 8.0
			vidaEnemy = 26
			escala_clase = 2.2
			radio_deteccion = 4.0
			escala_atkbox = 2.5
		ClaseEnemigo.JEFE:
			speed = 1.3
			daño = 12.0
			vidaEnemy = 48
			escala_clase = 2.8
			radio_deteccion = 5.0
			escala_atkbox = 3.5
	barra_vida.init_vida(vidaEnemy)

	#modifica las escalas del mesh y de la colision dependiendo la clase
	mesh_enemigo.scale *= Vector3.ONE * escala_clase
	colision_cuerpo.scale *= Vector3.ONE * escala_clase

	var mesh_bounds := mesh_enemigo.get_aabb()
	barra_vida_billboard.position.y = mesh_enemigo.position.y + (mesh_bounds.position.y + mesh_bounds.size.y) * mesh_enemigo.scale.y + 0.3

	var ataque := rangoAtaque.shape.duplicate() as BoxShape3D
	rangoAtaque.shape = ataque
	ataque.size *= Vector3(ataque.size.x*escala_atkbox,ataque.size.y*escala_atkbox,ataque.size.z*escala_atkbox)
	
	var deteccion := rangoDeteccion.shape.duplicate() as CylinderShape3D
	rangoDeteccion.shape = deteccion
	deteccion.radius = radio_deteccion	

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(playerPermanente) or not is_instance_valid(colisionPlayer):
		set_physics_process(false)
		return

	if vidaEnemy > 0.0:
		var vert_player = colisionPlayer.global_position.y + 0.1
		rangoAtaque.global_position.y = vert_player
		rangoDeteccion.global_position.y = vert_player
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
	else:
		morir()

func atacar():
	# Emitimos el dano una sola vez y esperamos a que termine el enfriamiento.
	if !cooldownAtk1:
		cooldownAtk1 = true
		daniar.emit(player,daño)
		timerAtk1.start()
		await timerAtk1.timeout
		cooldownAtk1 = false



func _on_areadeteccion_body_entered(body: Node3D) -> void:
	# Empieza la persecucion al detectar al jugador.
	if body.is_in_group("jugador"):
		player = body #Declara player como body para que empiece a calcular donde se encuentra el jugador a partir de aca
		perseguirDano = false


func _on_areadeteccion_body_exited(body: Node3D) -> void:
	# Detiene la persecucion cuando el jugador sale del area.
	if body == player and perseguirDano:
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

func _on_player_daniarobjetivo(quien: Node3D, cuanto: float) -> void:
	# Recibe dano solo si el objetivo coincide con este enemigo.
	if !quien:
		return
	if quien.get_class() == self.get_class() and quien.name == self.name:
		player = playerPermanente
		perseguirDano = !$AreaDeteccion.overlaps_body(playerPermanente)

		vidaEnemy -= cuanto
		barra_vida.set_vida(vidaEnemy)
		print(self.name," recibio ",cuanto," puntos de daño")

func morir():
	print(self.name," murio")
	GameManager.registrar_enemigo_derrotado()
	queue_free()
