extends RigidBody2D
class_name BasketBall
## Mini ball from the water toy. Floats, drifts and takes hits from the pumps.

@export var ball_radius: float = 20.0
@export var ball_color: Color = Color(0.95, 0.45, 0.15)
@export var ball_texture: Texture2D

var scored: bool = false
var _swim_phase: float = 0.0
var _swim_speed: float = 2.0

func _ready() -> void:
	gravity_scale = 0.6
	linear_damp = 1.8
	angular_damp = 2.2
	mass = 0.4
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 4
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.38
	mat.friction = 0.4
	physics_material_override = mat
	_swim_phase = randf() * TAU
	_swim_speed = randf_range(1.6, 3.0)
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = ball_radius
		col.shape = circle
		add_child(col)
	_ensure_sprite()
	_apply_scored_visual()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Water buoyancy plus a sway so they never sit still.
	var t := Time.get_ticks_msec() / 1000.0
	var sway := sin(t * _swim_speed + _swim_phase) * 22.0
	state.apply_central_force(Vector2(sway, -32.0))

func pump(side: float = 0.0) -> void:
	# side: -1 right jet pushes left, +1 the other way round, 0 centre jet.
	var up := randf_range(-260.0, -380.0)
	var lateral := side * randf_range(80.0, 150.0) + randf_range(-45.0, 45.0)
	apply_central_impulse(Vector2(lateral, up))
	apply_torque_impulse(randf_range(-50.0, 50.0))

func set_scored(value: bool) -> void:
	scored = value
	_apply_scored_visual()

func _ensure_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	if ball_texture != null:
		sprite.texture = ball_texture
	# 64px asset with a ~60px ball: scaled so it lines up with ball_radius
	# (physical diameter = ball_radius * 2).
	var world_diameter := ball_radius * 2.0
	sprite.scale = Vector2.ONE * (world_diameter / 60.0)

func _apply_scored_visual() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	if scored:
		sprite.modulate = Color(1.0, 0.85, 0.45)
	else:
		sprite.modulate = Color.WHITE