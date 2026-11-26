extends ProgressBar

# Referencias a los temporizadores y a la barra secundaria que muestra el dano retardado.
@onready var timer: Timer = $Timer
@onready var barra_de_dano: ProgressBar = get_node_or_null("BarraDeDano") as ProgressBar

# Guarda la vida actual y actualiza su barra al asignar un nuevo valor.
var vida: float = 0.0 : set = _set_vida

func _ready() -> void:
	pass

func _set_vida(nueva_vida: float) -> void:
	# Conserva la vida anterior y limita el nuevo valor entre cero y el maximo.
	var prev_vida := vida
	vida = clamp(nueva_vida, 0.0, max_value)
	value = vida
	
	# Inicia el retraso visual al recibir dano o actualiza la barra al recuperarse.
	if vida < prev_vida:
		timer.start()
	elif barra_de_dano != null:
		barra_de_dano.value = vida

func init_vida(_vida: float) -> void:
	# Configura los valores iniciales de la barra principal y la secundaria.
	max_value = _vida
	vida = _vida
	if barra_de_dano != null:
		barra_de_dano.max_value = _vida
		barra_de_dano.value = vida

func set_vida(nueva_vida: float) -> void:
	vida = nueva_vida

func _on_timer_timeout() -> void:
	# Hace que la barra secundaria alcance lentamente el dano recibido.
	if barra_de_dano != null:
		barra_de_dano.value = vida
