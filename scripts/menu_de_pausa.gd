extends Control

# Reanuda el juego desactivando la pausa global.
func _on_seguir_jugando_pressed() -> void:
	GameManager.pauseMenu()


func _on_opciones_pressed() -> void:
	pass # Replace with function body.

# Cierra completamente la aplicacion.
func _on_salir_pressed() -> void:
	get_tree().quit()

# Cambia desde el menu de pausa hacia la escena del menu principal.
func _on_salir_al_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
