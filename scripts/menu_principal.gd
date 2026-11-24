extends Control

# Carga anticipada de la escena principal del juego.
@onready var main: PackedScene = load("res://scenes/main.tscn")
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

# Inicia la partida cargando la escena principal.
func _on_iniciar_pressed() -> void:
	print("Iniciar Presionado")
	get_tree().change_scene_to_packed(main)

func _on_opciones_pressed() -> void:
	print("Opciones Presionado")

# Cierra la aplicacion desde el menu principal.
func _on_salida_pressed() -> void:
	# print("Salir Presionado")
	get_tree().quit()
