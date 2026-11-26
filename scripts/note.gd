extends Area3D

@export var interact_distance: float = 1.8

const note_title: String = "De: Arata"
const note_text: String = "Hola Keith! Tuve que irme a una misión, disculpa por no avisarte antes, no quise despertarte. En mi ausencia, te pido que derrotes a unas criaturas cerca de los pilares.\n Y procura no quemar la casa, se que no lo harás. Nos vemos en unos días.\n\nPor cierto, te dejé comida para rato.\n\nSuerte!"

var _player: Node3D
var _key_was_pressed: bool = false
var _panel: PanelContainer

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("jugador") as Node3D
	_build_ui()

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = -1
	add_child(ui)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -260.0
	_panel.offset_right = 260.0
	_panel.offset_top = -160.0
	_panel.offset_bottom = 160.0
	ui.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var content := VBoxContainer.new()
	margin.add_child(content)

	var title := Label.new()
	title.text = note_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var message := Label.new()
	message.text = note_text
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 15)
	content.add_child(message)

	var hint := Label.new()
	hint.text = "\n[E] Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	content.add_child(hint)

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("jugador") as Node3D

	var e_pressed := Input.is_key_pressed(KEY_E)
	var can_interact := _panel.visible
	if _player != null:
		var distance_squared := global_position.distance_squared_to(_player.global_position)
		can_interact = can_interact or distance_squared < interact_distance * interact_distance

	if can_interact and e_pressed and not _key_was_pressed:
		_panel.visible = not _panel.visible

	_key_was_pressed = e_pressed
