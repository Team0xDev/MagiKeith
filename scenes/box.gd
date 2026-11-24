extends Node3D

# Identificador de prueba usado por la configuracion exportada.
const CAT_TEST:StringName="TEST_CAT"
@export_category(CAT_TEST)
@export var vidaBase:float = 99999999.0

func _on_player_daniarobjetivo(quien: Node3D, cuanto: int) -> void:
	# Recibe dano solo si la senal pertenece a esta misma instancia.
	if !quien:
		return
	if quien.get_class() == self.get_class() and quien.name == self.name:
		vidaBase -= cuanto
		print(self.name," recibio ",cuanto," puntos de daño")
