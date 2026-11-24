extends CanvasLayer

# Texturas usadas para mostrar disponibilidad y enfriamiento de habilidades.
const MOUSE_LEFT_LIGHT := preload("res://assets/textures/left_mouse_button_light.png")
const MOUSE_LEFT_DARK := preload("res://assets/textures/left_mouse_button_dark.png")
const MOUSE_RIGHT_LIGHT := preload("res://assets/textures/right_mouse_button_light.png")
const MOUSE_RIGHT_DARK := preload("res://assets/textures/right_mouse_button_dark.png")
const SHIFT_PRESSED := preload("res://assets/textures/Omies_Assets_Controller_Keyboard_Input_Icons/Keyboard/Modifiers/KeyboardIcon_Shift_Pressed.png")
const SHIFT_UNPRESSED := preload("res://assets/textures/Omies_Assets_Controller_Keyboard_Input_Icons/Keyboard/Modifiers/KeyboardIcon_Shift_Unpressed.png")

# Referencias a indicadores, temporizadores y datos del jugador.
@onready var h1: TextureRect = $Control/Panel1/IndicadorHabilidad1
@onready var h2: TextureRect = $Control/Panel2/IndicadorHabilidad2
@onready var h3: TextureRect = $Control/Panel3/IndicadorCorrer
@onready var texto_carga: Label = $Control/Panel2/TiempoCarga
@onready var texto_mision: Label = $Control/TextoMision
var timerMelee: Timer
var timerRange: Timer
@onready var jugador := get_tree().get_first_node_in_group("jugador")
@onready var anim_player: AnimationPlayer = jugador.get_node("AnimationPlayer")

func _ready() -> void:
	# Inicializa iconos, oculta mensajes y conecta el evento de mision completa.
	h1.texture = MOUSE_LEFT_LIGHT
	h2.texture = MOUSE_RIGHT_LIGHT
	h3.texture = SHIFT_UNPRESSED
	texto_carga.hide()
	texto_mision.hide()
	if not GameManager.mision_completada.is_connected(_mostrar_mision_completa):
		GameManager.mision_completada.connect(_mostrar_mision_completa)
	if GameManager.mision_completa:
		_mostrar_mision_completa()
	timerMelee = jugador.get_node_or_null("Grupo - Timers/TimerMelee") as Timer
	timerRange = jugador.get_node_or_null("Grupo - Timers/TimerRange") as Timer
	
func _process(_delta: float) -> void:
	# Oculta el HUD si el jugador ya no existe.
	if murio_player():
		queue_free()

	h3.texture = SHIFT_PRESSED if anim_player.current_animation == "Run" else SHIFT_UNPRESSED
	_actualizar_tiempo_carga()

	# Actualiza los iconos segun el estado de los enfriamientos.
	if timerMelee == null or timerRange == null:
		return

	h1.texture = MOUSE_LEFT_LIGHT if timerMelee.time_left == 0.0 else MOUSE_LEFT_DARK
	h2.texture = MOUSE_RIGHT_LIGHT if timerRange.time_left == 0.0 else MOUSE_RIGHT_DARK

func _actualizar_tiempo_carga() -> void:
	# Muestra y calcula el tiempo restante mientras se carga el ataque a distancia.
	var esta_cargando := bool(jugador.get("rangoCargando")) and not bool(jugador.get("rangoCargaReversa"))
	texto_carga.visible = esta_cargando
	if not esta_cargando:
		return

	var tiempo_restante := maxf(
		float(jugador.get("cargaRange")) - float(jugador.get("tiempoCargaRange")),
		0.0
	)
	texto_carga.text = "%.1fs" % tiempo_restante

func _mostrar_mision_completa() -> void:
	# Presenta el aviso de mision completa y lo desvanece despues de unos segundos.
	texto_mision.text = "Mision completa!"
	texto_mision.modulate = Color.WHITE
	texto_mision.show()
	await get_tree().create_timer(3.0).timeout
	var tween := create_tween()
	tween.tween_property(texto_mision, "modulate:a", 0.0, 1.0)
	await tween.finished
	texto_mision.hide()

func murio_player():
	var sjugador := get_tree().get_first_node_in_group("jugador")
	if sjugador == null:
		return true
