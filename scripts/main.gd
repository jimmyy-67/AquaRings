extends Node2D
## Water basketball game like the toy in the photo.
## Central tank, green hoop on top, 9 floating mini balls, 2 pumps at the bottom.
## Keyboard: A / Left arrow = left pump, D / Right arrow = right pump, Space = both, left/right click works the same.

const BallScene: PackedScene = preload("res://scenes/ball.tscn")

const TANK_RECT := Rect2(460, 120, 360, 480)
const HOOP_Y := 240.0
const HOOP_LEFT_X := 595.0
const HOOP_RIGHT_X := 685.0
const NUM_BALLS := 9
	# Anti-cheat valve: blocks passing upward through the hoop from below.
	# The HoopValve in main.tscn (one-way upward) already prevents it physically;
	# this code level stop makes it impossible even if a fast ball tunnels through.
const VALVE_HALF_WIDTH := 37.0
const VALVE_BLOCK_DIST := 34.0

const BALL_COLORS := [
	Color(0.9, 0.2, 0.2),    # rojo
	Color(0.95, 0.55, 0.15), # naranja basket
	Color(0.95, 0.8, 0.2),   # amarillo
	Color(0.3, 0.8, 0.35),   # verde
	Color(0.9, 0.2, 0.2),
	Color(0.95, 0.55, 0.15),
	Color(0.95, 0.8, 0.2),
	Color(0.3, 0.8, 0.35),
	Color(0.95, 0.55, 0.15),
]

const BALL_TEXTURES := [
	preload("res://assets/sprites/ball_red.png"),
	preload("res://assets/sprites/ball_orange.png"),
	preload("res://assets/sprites/ball_yellow.png"),
	preload("res://assets/sprites/ball_green.png"),
]

var balls: Array[BasketBall] = []
var score: int = 0
	# Top-only history: only counts if the ball was above the hoop before entering.
var _was_above: Dictionary = {}
	# If the ball came up from below through the hoop, the next descent does not count.
	# It resets on its own once the ball moves clearly away, well above or well below.
var _came_from_below: Dictionary = {}
	# Previous height of each ball, used to detect the hoop plane crossing.
var _prev_y: Dictionary = {}

@onready var balls_container: Node2D = $Balls
@onready var score_area: Area2D = $ScoreArea
@onready var jet_left: CPUParticles2D = $JetLeft
@onready var jet_left_tiny: CPUParticles2D = $JetLeftTiny
@onready var jet_right: CPUParticles2D = $JetRight
@onready var jet_right_tiny: CPUParticles2D = $JetRightTiny
@onready var score_fx: CPUParticles2D = $ScoreFX
@onready var left_pump: TextureButton = $UI/BottomBar/LeftPump
@onready var right_pump: TextureButton = $UI/BottomBar/RightPump

	# Quick 10 frame full colour pop: 0 idle, 1-5 pressed, 6-9 bouncing back.
	# No cooldown: every press pumps instantly. Frames are loaded in _ready.
const PRESS_COUNT := 10
const FRAME60 := 1.0 / 60.0
var _left_press: Array[Texture2D] = []
var _right_press: Array[Texture2D] = []
	# Keeps the active sequence per button so a new press cancels the previous one.
var _pump_anim_seq: Dictionary = {}

func _ready() -> void:
	randomize()
	_load_pump_frames()
	spawn_balls()
	score_area.body_entered.connect(_on_score_area)
	$UI/TopBar/ResetButton.pressed.connect(reset_game)
	# button_down gives an immediate response on press.
	left_pump.button_down.connect(func() -> void: pump_left())
	right_pump.button_down.connect(func() -> void: pump_right())
	_update_ui()

func spawn_balls() -> void:
	for i in NUM_BALLS:
		var ball := BallScene.instantiate() as BasketBall
		var color_idx := i % BALL_COLORS.size()
		ball.ball_color = BALL_COLORS[color_idx]
		ball.ball_texture = BALL_TEXTURES[color_idx % BALL_TEXTURES.size()]
		ball.position = Vector2(
			randf_range(TANK_RECT.position.x + 45.0, TANK_RECT.end.x - 45.0),
			randf_range(450.0, 560.0)
		)
		balls_container.add_child(ball)
		balls.append(ball)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pump_left"):
		pump_left()
	elif event.is_action_pressed("pump_right"):
		pump_right()
	elif event.is_action_pressed("shoot") or event.is_action_pressed("pump"):
		pump_both()
	elif event.is_action_pressed("reset_game"):
		reset_game()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Click left of centre = left pump, right of centre = right pump.
			if mb.position.x < 640.0:
				pump_left()
			else:
				pump_right()

func _process(_delta: float) -> void:
	_check_unscore()

func _physics_process(_delta: float) -> void:
	# Main detection: crossing the hoop plane from top to bottom.
	# It does not depend on body_entered timing, so a slow entry
	# after bouncing off the rim still counts.
	# The Area2D stays as a fallback.
	var center_x := (HOOP_LEFT_X + HOOP_RIGHT_X) * 0.5
	for ball in balls:
		if not is_instance_valid(ball):
			continue
		var id := ball.get_instance_id()
		var pos := ball.global_position
		var prev: float = _prev_y.get(id, pos.y)
		var inside := absf(pos.x - center_x) <= 38.0
		# Code level physical valve: passing upward from below is impossible.
		# It only acts while going up (vel.y < 0) and inside the hoop gap.
		# Coming down from above it does nothing, so scoring is never slowed.
		if absf(pos.x - center_x) <= VALVE_HALF_WIDTH:
			var vel: Vector2 = ball.linear_velocity
			var min_center_y := HOOP_Y + ball.ball_radius + 2.0
			if prev >= HOOP_Y and pos.y < HOOP_Y:
				# Tunnelled in one frame: put it back below and kill the impulse.
				ball.global_position = Vector2(pos.x, min_center_y)
				ball.linear_velocity = Vector2(vel.x * 0.3, 60.0)
				pos = ball.global_position
			elif vel.y < 0.0 and pos.y > HOOP_Y and pos.y < HOOP_Y + VALVE_BLOCK_DIST:
				ball.linear_velocity = Vector2(vel.x * 0.5, maxf(vel.y * -0.15, 30.0))
				if pos.y < min_center_y:
					ball.global_position = Vector2(pos.x, min_center_y)
					pos = ball.global_position
		# Passing up from below through the hoop: invalidates the next descent.
		# Without this, a ball that rises from below, pokes slightly above
		# and falls back down would count as a score even though it never came from above.
		if prev >= HOOP_Y and pos.y < HOOP_Y and inside:
			_came_from_below[id] = true
		elif pos.y < HOOP_Y - 80.0 or pos.y > HOOP_Y + 50.0:
			# Ball clearly away from the hoop: a new attempt is valid.
			_came_from_below[id] = false
		if prev < HOOP_Y and pos.y >= HOOP_Y:
			_try_score_crossing(ball)
		_prev_y[id] = pos.y
		# Marks which balls were clearly above the hoop.
		# This way a touch from below can never count in the Area2D, even if
		# it bounces and the velocity flips on the same frame as body_entered.
		if pos.y < HOOP_Y - 18.0:
			_was_above[id] = true
		elif pos.y > HOOP_Y + 50.0:
			_was_above[id] = false

func _fire_bubbles(big: CPUParticles2D, tiny: CPUParticles2D) -> void:
	for jet in [big, tiny]:
		if is_instance_valid(jet):
			jet.restart()
			jet.emitting = true

func _load_pump_frames() -> void:
	_left_press.clear()
	_right_press.clear()
	for i in PRESS_COUNT:
		_left_press.append(load("res://assets/sprites/button_A_press_%02d.png" % i) as Texture2D)
		_right_press.append(load("res://assets/sprites/button_D_press_%02d.png" % i) as Texture2D)

func _animate_pump(btn: TextureButton, press: Array[Texture2D]) -> void:
	# 0.15s full colour pop. No tweens: everything comes from the sprites.
	if not is_instance_valid(btn):
		return
	if press.size() < PRESS_COUNT or press[0] == null:
		return
	var id := btn.get_instance_id()
	_pump_anim_seq[id] = int(_pump_anim_seq.get(id, 0)) + 1
	_play_pump_frames(btn, id, int(_pump_anim_seq[id]), press)

func _show_pump_frame(btn: TextureButton, tex: Texture2D) -> void:
	# Both normal and hover are updated: without texture_pressed, holding the button
	# would show the static hover image and cover the animation.
	btn.texture_normal = tex
	btn.texture_hover = tex

func _play_pump_frames(btn: TextureButton, id: int, my_seq: int, press: Array[Texture2D]) -> void:
	for i in range(1, PRESS_COUNT):
		await get_tree().create_timer(FRAME60).timeout
		if not is_instance_valid(btn) or _pump_anim_seq.get(id, 0) != my_seq:
			return
		_show_pump_frame(btn, press[i])
	await get_tree().create_timer(FRAME60).timeout
	if not is_instance_valid(btn) or _pump_anim_seq.get(id, 0) != my_seq:
		return
	_show_pump_frame(btn, press[0])

func pump_left() -> void:
	_animate_pump(left_pump, _left_press)
	for ball in balls:
		if is_instance_valid(ball):
			ball.pump(1.0)
	_fire_bubbles(jet_left, jet_left_tiny)

func pump_right() -> void:
	_animate_pump(right_pump, _right_press)
	for ball in balls:
		if is_instance_valid(ball):
			ball.pump(-1.0)
	_fire_bubbles(jet_right, jet_right_tiny)

func pump_both() -> void:
	_animate_pump(left_pump, _left_press)
	_animate_pump(right_pump, _right_press)
	for ball in balls:
		if is_instance_valid(ball):
			ball.pump(0.0)
	_fire_bubbles(jet_left, jet_left_tiny)
	_fire_bubbles(jet_right, jet_right_tiny)

func reset_game() -> void:
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()
	_was_above.clear()
	_came_from_below.clear()
	_prev_y.clear()
	score = 0
	spawn_balls()
	_update_ui()

func hoop_center() -> Vector2:
	return Vector2((HOOP_LEFT_X + HOOP_RIGHT_X) * 0.5, HOOP_Y + 8.0)

func _on_score_area(body: Node2D) -> void:
	if not body is BasketBall:
		return
	var ball := body as BasketBall
	if ball.scored:
		return
	# Only from above: it has to come down falling, centred, and have
	# been above the hoop before entering.
	if ball.linear_velocity.y < 20.0:
		return
	if absf(ball.linear_velocity.x) > 260.0:
		return
	var center_x := (HOOP_LEFT_X + HOOP_RIGHT_X) * 0.5
	if absf(ball.global_position.x - center_x) > 38.0:
		return
	if ball.global_position.y > HOOP_Y + 14.0:
		return
	if not _was_above.get(ball.get_instance_id(), false):
		return
	if _came_from_below.get(ball.get_instance_id(), false):
		return
	_award(ball)

func _try_score_crossing(ball: BasketBall) -> void:
	# The centre crossed the hoop plane from top to bottom.
	# We also require top-only history: having been clearly above
	# and not having come up from below through the hoop just before.
	if ball.scored:
		return
	if ball.linear_velocity.y <= 0.0:
		return
	if absf(ball.linear_velocity.x) > 260.0:
		return
	var center_x := (HOOP_LEFT_X + HOOP_RIGHT_X) * 0.5
	if absf(ball.global_position.x - center_x) > 38.0:
		return
	if not _was_above.get(ball.get_instance_id(), false):
		return
	if _came_from_below.get(ball.get_instance_id(), false):
		return
	_award(ball)

func _award(ball: BasketBall) -> void:
	_was_above[ball.get_instance_id()] = false
	ball.set_scored(true)
	score += 1
	score_fx.restart()
	score_fx.emitting = true
	_update_ui()

func _check_unscore() -> void:
	# If a scored ball leaves the hoop, it loses the point.
	var changed := false
	for ball in balls:
		if is_instance_valid(ball) and ball.scored:
			if ball.global_position.distance_to(hoop_center()) > 75.0:
				ball.set_scored(false)
				score = maxi(0, score - 1)
				changed = true
	if changed:
		_update_ui()

func _update_ui() -> void:
	pass
