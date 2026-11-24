extends Area3D

# Nota sobre la mesa. Pulsa E cerca para leerla.

@export var interact_distance: float = 1.8
@export var note_title: String = "Nota para Keith"
@export var note_text: String = "Hola Keith! Tuve que irme a una misión, disculpa por no avisarte antes, no quise despertarte. En mi ausencia, te dejo una pequeña lista de objetos, son muy importantes, procura no quemar la casa, se que no lo harás. Nos vemos en unos días.\n\nPor cierto, te dejé comida para rato.\n\nSuerte!"

var _player: Node3D = null
var _showing: bool = false
var _key_was_pressed: bool = false
var _ui: CanvasLayer = null
var _panel: PanelContainer = null
var _label: Label = null

func _ready() -> void:
	# Encuentra al jugador, crea la interfaz y mantiene la nota oculta al iniciar.
	_player = get_tree().get_first_node_in_group("jugador") as Node3D
	_build_ui()
	_hide_note()

func _build_ui() -> void:
	# Construye una capa superior con el panel, el texto y la indicacion de cierre.
	_ui = CanvasLayer.new()
	_ui.layer = 20

	add_child(_ui)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260.0
	_panel.offset_right = 260.0
	_panel.offset_top = -160.0
	_panel.offset_bottom = 160.0
	_ui.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = note_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_label = Label.new()
	_label.text = note_text
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_label)

	var hint := Label.new()
	hint.text = "\n[E] Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hint)

func _process(_delta: float) -> void:
	# Busca al jugador si aun no se ha registrado.
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return

	var dist: float = global_position.distance_to(_player.global_position)
	var can_interact: bool = dist < interact_distance
	var e_pressed: bool = Input.is_key_pressed(KEY_E)

	# Alterna la visibilidad al pulsar E dentro del radio de interaccion.
	if can_interact and e_pressed and not _key_was_pressed:
		if _showing:
			_hide_note()
		else:
			_show_note()

	_key_was_pressed = e_pressed

func _show_note() -> void:
	# Marca la nota como visible y muestra su panel.
	_showing = true
	if _panel != null:
		_panel.visible = true

func _hide_note() -> void:
	# Marca la nota como cerrada y oculta su panel.
	_showing = false
	if _panel != null:
		_panel.visible = false
