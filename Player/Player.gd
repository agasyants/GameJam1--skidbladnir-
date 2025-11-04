extends CharacterBody2D
class_name Player

# Константы движения
const SPEED = 600.0
const JUMP_VELOCITY = -1500.0
const ACCELERATION = 4000.0
const FRICTION = 4000.0
const GRAVITY = 3400.0
const FAST_FALL_GRAVITY = 3500.0

# Дополнительные параметры
const COYOTE_TIME = 0.08
const JUMP_BUFFER = 0.12
const STUCK_TIME = 8.0
const MAX_FALL_SPEED = 1400.0

# Состояния
enum State { IDLE, WALK, JUMP, FALL }
var player_state: State = State.IDLE
var eye_state = 0

var camera_offset: Vector2 = Vector2(0, -140)

func set_camera_offset(offset):
	camera_offset = offset

func set_camera_zoom(zoom):
	camera.zoom = zoom

@onready var camera: Camera2D = get_viewport().get_camera_2d()

# Таймеры
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var stuck_timer = 0.0

@onready var animation_player = $AnimationPlayer
@onready var viniet = get_tree().get_first_node_in_group("V")

func _ready() -> void:
	var loaded = SaveManager.load_game()
	if loaded:
		eye_state = int(loaded["eyes"])
		global_position = Vector2(loaded["position_x"], loaded["position_y"])

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal_movement(delta)
	_handle_jump()
	_update_state()
	
	var prev = global_position
	
	move_and_slide()
	
	camera.position = camera.position - global_position + prev
	camera.position = camera.position.lerp(camera_offset, 1.0 - exp(-10.0 * delta))
	
	if test_move(global_transform, Vector2.ZERO):
		stuck_timer += delta
		viniet.set_intensity(stuck_timer/STUCK_TIME)
		viniet.set_size1(1.1-stuck_timer/STUCK_TIME*0.7)
		if stuck_timer > STUCK_TIME:
			die()
	else:
		viniet.set_intensity(0.0)
		viniet.set_size1(1.2)
		stuck_timer = 0.0

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		# Быстрое падение - если падаем вниз или отпустили прыжок
		var current_gravity = GRAVITY
		if velocity.y > 0:
			current_gravity = FAST_FALL_GRAVITY
		
		velocity.y += current_gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		if velocity.y > 0:
			velocity.y = 0

func _handle_horizontal_movement(delta: float) -> void:
	var input_axis = Input.get_axis("ui_left", "ui_right")
	var current_accel = ACCELERATION if is_on_floor() else ACCELERATION * 0.8

	if input_axis != 0:
		velocity.x = move_toward(velocity.x, SPEED * input_axis, current_accel * delta)
		$Sprite2D.flip_h = input_axis < 0
	else:
		var current_friction = FRICTION if is_on_floor() else FRICTION * 0.4
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	
	var can_jump = is_on_floor() or coyote_timer > 0
	
	if can_jump and jump_buffer_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	# РЕЗКОЕ снижение прыжка при отпускании
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.4  # Ещё более резкое

func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

func _update_state() -> void:
	var state_str = str(eye_state)
	if eye_state > 2:
		state_str = "2"
	if not is_on_floor():
		if velocity.y < 0:
			player_state = State.JUMP
			animation_player.play("jump" + state_str)
		else:
			player_state = State.FALL
			animation_player.play("fall" + state_str)
	elif abs(velocity.x) > 10:
		player_state = State.WALK
		animation_player.play("walk" + state_str)
	else:
		player_state = State.IDLE
		animation_player.play("idle" + state_str)

func get_state_name() -> String:
	match player_state:
		State.IDLE: return "idle"
		State.WALK: return "walk"
		State.JUMP: return "jump"
		State.FALL: return "fall"
		_: return "idle"

func die():
	var checkpoint = GameManager.get_checkpoint_data()
	if checkpoint.is_empty():
		get_tree().reload_current_scene()  # Перезапуск уровня
	else:
		# Восстанавливаем состояние
		global_position = Vector2(checkpoint["position_x"], checkpoint["position_y"])
		eye_state = int(checkpoint["eyes"])
