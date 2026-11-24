extends Node3D

# Nombre de animacion que debe reproducirse al cargar el gato.
@export var autoplay_animation: StringName = &"Idle"

func _ready() -> void:
	# Aplica el material del rabo y reproduce la animacion inicial disponible.
	_apply_tail_material()
	var ap := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null and ap.has_animation(autoplay_animation):
		ap.play(autoplay_animation)

func _apply_tail_material() -> void:
	# Localiza la carpeta del proyecto y carga las texturas del shader.
	var dir: String = get_script().resource_path.get_base_dir().get_base_dir()
	dir = dir + "assets/"
	# print(dir)
	var mat := ShaderMaterial.new()
	mat.shader = load(dir + "shaders/tail_pulse.gdshader")
	mat.set_shader_parameter("pulse_color", load(dir + "textures/Cat_Tail_PulseColor.png"))
	mat.set_shader_parameter("pulse_mask", load(dir + "textures/Cat_Tail_PulseMask.png"))
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var sm := mi.mesh.surface_get_material(i)
			if sm != null and sm.resource_name == "Cat_Tail":
				mi.set_surface_override_material(i, mat)
