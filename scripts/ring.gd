extends RigidBody2D
class_name AquaRing
## Aro flotante del juego Aqua Rings.
## Visual = asset real (res://assets/sprites/ring.png), sin dibujo procedural.
## Colisión tipo dona: 12 CollisionShape2D definidos en ring.tscn, centro hueco.

var scored: bool = false
var _swim_phase: float = 0.0
var _swim_speed: float = 2.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	gravity_scale = 0.35
	linear_damp = 1.2
	angular_damp = 2.5
	mass = 0.6
	_swim_phase = randf() * TAU
	_swim_speed = randf_range(1.5, 2.8)
	# Material físico suave y rebotón como plástico en agua.
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.45
	mat.friction = 0.6
	physics_material_override = mat
	_apply_scored_visual()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Corriente de agua: flotación + vaivén lateral para que nunca se quede quieto.
	var t := Time.get_ticks_msec() / 1000.0
	var sway := sin(t * _swim_speed + _swim_phase) * 28.0
	var float_up := -42.0
	state.apply_central_force(Vector2(sway, float_up))

func pump(strength: float = 1.0) -> void:
	# Llamado por Main cuando se pulsa la bomba.
	# Impulso hacia arriba + aleatoriedad lateral + giro.
	var side := randf_range(-160.0, 160.0)
	var up := randf_range(-620.0, -880.0) * strength
	apply_central_impulse(Vector2(side, up))
	apply_torque_impulse(randf_range(-90.0, 90.0))

func set_scored(value: bool) -> void:
	scored = value
	_apply_scored_visual()

func _apply_scored_visual() -> void:
	if not is_instance_valid(_sprite):
		return
	# Sin _draw: el brillo dorado de encestado se hace con modulate del sprite.
	if scored:
		_sprite.modulate = Color(1.0, 0.85, 0.45)
	else:
		_sprite.modulate = Color.WHITE
