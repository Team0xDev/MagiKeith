extends RayCast3D

@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var beam_cylinder: CylinderMesh = beam_mesh.mesh as CylinderMesh 
@onready var beam_particles: GPUParticles3D = $BeamParticles
@onready var beam_particle_material: ParticleProcessMaterial = beam_particles.process_material as ParticleProcessMaterial
@onready var end_particles: GPUParticles3D = $EndParticles

# Estado y dimensiones usadas para extender y contraer el haz.
var tween: Tween
var beam_radius: float = 0.1
# var laser_cycle_started: bool = false

func _process(_delta: float) -> void:
	# Cada frame ajusta el rayo y sus particulas hasta el punto de colision.
	var cast_point: Vector3
	force_raycast_update() 
	if is_colliding() and visible: #Si el raycast esta colisionando con algo y si su propiedad visible esta activa
		cast_point = to_local(get_collision_point()) #Convierte el punto de colision del rayo, en coordenadas globales, a coordenadas locales del nodo
		beam_cylinder.height = cast_point.y #Extiende la altura del cilindro hasta las coordenadas locales previamente definidas
		beam_mesh.position.y = cast_point.y / 2.0 #Mueve el cilindro hasta la mitad de las coordenadas locales
		end_particles.position.y = cast_point.y #Mueve las particulas de impacto hasta las coordenadas locales
		beam_particles.position.y = cast_point.y / 2.0
		beam_particles.amount = maxi(1, int(abs(cast_point.y) * 30.0))
		beam_particle_material.emission_box_extents.y = abs(cast_point.y) / 2.0
	
func activate(time: float, _modifier: float = 0):
	# Amplia el cilindro y las particulas mediante una animacion.
	tween = get_tree().create_tween()
	visible = true
	beam_particles.emitting = true
	end_particles.emitting = true
	tween.set_parallel(true)
	tween.tween_property(beam_cylinder,"top_radius",beam_radius,time)
	tween.tween_property(beam_cylinder,"bottom_radius",beam_radius,time)
	tween.tween_property(beam_particles.process_material,"scale_min",1,time)
	tween.tween_property(end_particles.process_material,"scale_min",1,time)
	await tween.finished
func deactivate(time: float):
	# Contrae el laser y oculta el haz junto con sus particulas.
	tween = get_tree().create_tween()
	visible = true
	tween.set_parallel(true)
	tween.tween_property(beam_cylinder,"top_radius",0.0,time)
	tween.tween_property(beam_cylinder,"bottom_radius",0.0,time)
	tween.tween_property(beam_particles.process_material,"scale_min",0.0,time)
	tween.tween_property(end_particles.process_material,"scale_min",0.0,time)
	await tween.finished
	# print("FIN LASER")
	visible = false	
	beam_particles.emitting = false
	end_particles.emitting = false
