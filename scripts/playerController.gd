extends CharacterBody3D

# Ajustes exportables de movimiento, combate, vida y carga.
@export var anim_speed:float = 1.0
@export var vel_base:float = 3.0
@export var rangoMelee:float = 2.0
@export var danioMelee:float = 5.0
@export var danioRange:float = 2.0
@export var vidaBase: float = 100.0
@export var cargaRange: float = 1.52
@export var regeneracionVida: float = 2.5
@export var intervaloRegeneracion: float = 5.0

# Referencias a temporizadores, animaciones y areas de ataque.
@onready var timerMelee: Timer = $"Grupo - Timers/TimerMelee"
@onready var timerRange: Timer = $"Grupo - Timers/TimerRange"
@onready var nodo_rotable: Node3D = $Rotable
@onready var colision = $ColisionGato
@onready var animPlayer: AnimationPlayer = $AnimationPlayer
@onready var yoMismo = self
@onready var laser: Node = $Rotable/AreaRango/RangoRange/Laser
@onready var slash: VisualInstance3D = $Rotable/AreaMelee/RangoMelee/Slash
@onready var posicionInicialSlash: Vector3 = slash.position
@onready var transparenciaInicialSlash: float = slash.transparency
@onready var barra_vida: ProgressBar = get_tree().get_first_node_in_group("barra_vida")
@onready var animaciones = animPlayer.get_animation_list()
# 0 - AttackLaser
# 1 - AttackMelee
# 2 - Idle
# 3 - Idle_to_Run
# 4 - Idle_to_Walk
# 5 - Run
# 6 - Run_to_Idle
# 7 - Walk
# 8 - Walk_to_Idle

signal daniarObjetivo(quien: Node, cuanto: int)

# Estado de ataques, carga, movimiento y objetivo seleccionado.
var meleeCooldown: bool = false
var corriendo: bool = false
var rangoAtacando: bool = false
var rangoCargando: bool = false
var rangoCargaReversa: bool = false
var tiempoCargaRange: float = 0.0
var tiempoRegeneracion: float = 0.0
var vidaMaxima: float = 0.0
var nodoObjetivo: Node
var speed = vel_base

func _ready() -> void:
	# Guarda la vida maxima y conecta los enemigos con la senal de dano.
	vidaMaxima = vidaBase
	for atacable in get_tree().get_nodes_in_group("atacables"):
		daniarObjetivo.connect(atacable._on_player_daniarobjetivo)

	if barra_vida != null:
		barra_vida.init_vida(vidaBase)

func _physics_process(delta: float) -> void:
	# Termina el proceso inmediatamente si el personaje ya murio.
	if vidaBase	<= 0:
		morir()
		return
	# Acumula tiempo y aplica regeneracion periodica de vida.
	tiempoRegeneracion += delta
	while tiempoRegeneracion >= intervaloRegeneracion:
		tiempoRegeneracion -= intervaloRegeneracion
		var vidaAnterior := vidaBase
		vidaBase = minf(vidaBase + regeneracionVida, vidaMaxima)
		if vidaBase != vidaAnterior and barra_vida != null:
			barra_vida.set_vida(vidaBase)
	
	if !rangoCargando:
		animPlayer.speed_scale = anim_speed #Modifica la velocidad de la animacion que se ejecuta
	# Gestiona el ataque a distancia antes de calcular el movimiento.
	procesoRange()
	var direction := Input.get_vector("Izquierda", "Derecha", "Arriba", "Abajo") #Detecta la tecla presionada
	# Obtiene los ejes horizontales del personaje para que el movimiento siga su rotacion en el editor.
	var player_right := global_basis.x
	# player_right.y = 0.0
	player_right = player_right.normalized()
	var player_forward := -global_basis.z
	# player_forward.y = 0.0
	player_forward = player_forward.normalized()
	# Convierte la entrada local en una direccion de movimiento en coordenadas globales.
	var movement_direction := player_right * direction.x + player_forward * -direction.y
	if rangoAtacando:
		velocity = Vector3(0.0, velocity.y - 20.0 * delta, 0.0)
	else:
		velocity = Vector3(movement_direction.x * speed, velocity.y - 20.0 * delta, movement_direction.z * speed)
	
	# Ejecuta la carrera con Shift y conserva la velocidad base al soltarla.
	if Input.is_key_pressed(KEY_SHIFT): #Sistema de correr
		corriendo = true #Si presionamos SHIFT setea la variable a true y speed pasa a ser 2
		speed = vel_base * 2
	else:
		corriendo = false #Si dejamos de presionar SHIFT setea la variable a false y speed pasa a ser 1
		speed = vel_base
	move_and_slide()
	
	# Reproduce movimientos y procesa el ataque cuerpo a cuerpo.
	if !rangoAtacando:
		animarMovimiento(direction, delta)
	procesoMelee()
	
func procesoMelee():
	# Cancela el ataque si no se cumplen las condiciones de entrada o objetivo.
	if rangoAtacando:
		return
	if !Input.is_action_just_pressed("click_m1"):
		return
	if !nodoObjetivo:
		return
	if meleeCooldown:
		print("Cooldown activo: ",snapped(timerMelee.time_left,0.2))
		return
	print("Attacked -> ",nodoObjetivo.name)
	slash.position = posicionInicialSlash
	slash.transparency = transparenciaInicialSlash
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(slash, "position", Vector3(0.160, posicionInicialSlash.y, 0.0), 0.15)
	tween.parallel().tween_property(slash, "transparency", 0.0, 0.15)
	tween.tween_property(slash, "position", Vector3(posicionInicialSlash.x, posicionInicialSlash.y, -absf(posicionInicialSlash.z)), 0.15)
	tween.parallel().tween_property(slash, "transparency", transparenciaInicialSlash, 0.15)
	meleeCooldown = true
	timerMelee.start()
	# animPlayer.play(animaciones[1])
	daniarObjetivo.emit(nodoObjetivo,danioMelee)
	await timerMelee.timeout
	meleeCooldown = false

func procesoRange() -> void:
	# Obtiene la animacion usada para calcular la carga del rayo.
	var animacion: Animation = animPlayer.get_animation(animaciones[0])
	# Mientras carga, permite soltar el boton para reducir la carga.
	if rangoCargando:
		if rangoCargaReversa:
			tiempoCargaRange = maxf(animPlayer.current_animation_position, 0.0) * cargaRange / animacion.length
			if animPlayer.current_animation_position <= 0.0:
				animPlayer.stop()
				rangoCargando = false
				rangoCargaReversa = false
				rangoAtacando = false
				animPlayer.speed_scale = anim_speed
			return

		if !Input.is_action_pressed("click_m2"): #or !is_instance_valid(nodoObjetivo):
			rangoCargaReversa = true
			animPlayer.speed_scale = -absf(animPlayer.speed_scale)
			return

		tiempoCargaRange = minf(animPlayer.current_animation_position, animacion.length) * cargaRange / animacion.length
		if animPlayer.current_animation_position >= animacion.length:
			tiempoCargaRange = cargaRange
			rangoCargando = false
			timerRange.start()
			_ejecutarAtaqueRange()
		return

	# Comienza una carga nueva si se presiona el boton y no hay enfriamiento.
	if !Input.is_action_just_pressed("click_m2"):
		return
	if rangoAtacando or timerRange.time_left > 0.0:
		return
	if !nodoObjetivo:
		return

	var direccionObjetivo := to_local(nodoObjetivo.global_position)
	direccionObjetivo.y = 0.0
	var rotacionObjetivo := atan2(-direccionObjetivo.z, direccionObjetivo.x)
	nodo_rotable.rotation.y = rotacionObjetivo
	colision.rotation.y = rotacionObjetivo

	rangoAtacando = true
	rangoCargando = true
	rangoCargaReversa = false
	tiempoCargaRange = 0.0
	animPlayer.speed_scale = animacion.length / cargaRange
	animPlayer.play(animaciones[0])

func _ejecutarAtaqueRange() -> void:
	# Activa el laser, causa dano periodico y finaliza el ataque con enfriamiento.
	tiempoCargaRange = cargaRange
	await laser.call("activate", 0.7, 0.1)
	var tiempoLaser := 0.0
	while tiempoLaser < 0.675:
		await get_tree().create_timer(0.235).timeout
		if nodoObjetivo:
			daniarObjetivo.emit(nodoObjetivo, danioRange)
		tiempoLaser += 0.5
	laser.call("deactivate", 0.2)
	rangoAtacando = false
	await timerRange.timeout
	print("cooldown terminado")
	

func animarMovimiento(direction,delta):
	# Selecciona caminata, carrera o reposo segun la entrada y el estado.
	if (direction != Vector2.ZERO) and (corriendo == false): #Sistema de animacion, si no presionamos shift el jugador se mostrara caminando
		nodo_rotable.rotation.y = lerp_angle(nodo_rotable.rotation.y, atan2(direction.x, direction.y) - PI / 2.0, 12.0 * delta) #Calculamos el angulo en donde apunta el jugador (AJUSTAR DEPENDIENDO DEL MODELO BLENDER)
		colision.rotation.y = lerp_angle(nodo_rotable.rotation.y, atan2(direction.x, direction.y) - PI / 2.0, 12.0 * delta) #Calculamos el angulo en donde apunta el jugador (AJUSTAR DEPENDIENDO DEL MODELO BLENDER)
		animPlayer.play("Walk") #Reproduce la animacion Walk
	if (direction != Vector2.ZERO) and (corriendo == true): #Sistema de animacion, si presionamos shift el jugador se mostrara corriendo
		nodo_rotable.rotation.y = lerp_angle(nodo_rotable.rotation.y, atan2(direction.x, direction.y) - PI / 2.0, 12.0 * delta) #Calculamos el angulo en donde apunta el jugador (AJUSTAR DEPENDIENDO DEL MODELO BLENDER)
		colision.rotation.y = lerp_angle(nodo_rotable.rotation.y, atan2(direction.x, direction.y) - PI / 2.0, 12.0 * delta) #Calculamos el angulo en donde apunta el jugador (AJUSTAR DEPENDIENDO DEL MODELO BLENDER)
		animPlayer.play("Run")
	if direction == Vector2.ZERO: #Si el personaje no se mueve se reproduce la animacion Idle
		animPlayer.play("Idle")
		


func _on_enemigo_daniar(quien: Node3D, cuanto: int) -> void:
	# Recibe dano solo si la senal corresponde a este personaje.
	if quien != yoMismo:
		return

	vidaBase = max(vidaBase - cuanto, 0.0)
	print(yoMismo.name, " recibio ", cuanto, " puntos de daño")

	if barra_vida != null:
		barra_vida.set_vida(vidaBase)

	if vidaBase <= 0.0:
		morir()


func _on_areamelee_body_entered(body: Node3D) -> void:
	# Guarda el cuerpo detectado como objetivo de ataque cuerpo a cuerpo.
	print("--/--")
	print(body.name)
	print("--//--")
	print(body.is_class("CharacterBody3D"))
	if nodoObjetivo == StaticBody3D:
		nodoObjetivo = null
		return
	nodoObjetivo = body


func _on_areamelee_body_exited(_body: Node3D) -> void:
	# Limpia el objetivo al salir del area cuerpo a cuerpo.
	nodoObjetivo = null

func morir() -> void:
	# Elimina al personaje de la escena al quedarse sin vida.
	print(self.name," murio")
	queue_free()

func _on_arearango_body_exited(_body: Node3D) -> void:
	# Limpia el objetivo al salir del area de ataque a distancia.
	nodoObjetivo = null


func _on_arearango_body_entered(body: Node3D) -> void:
	# Guarda el cuerpo detectado como objetivo a distancia.
	if body != null: print(body.name)
	if nodoObjetivo == StaticBody3D:
		nodoObjetivo = null
		return
	nodoObjetivo = body
