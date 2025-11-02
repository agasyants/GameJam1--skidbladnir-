extends CharacterBody2D
class_name Player

# Константы движения
const SPEED = 600.0
const JUMP_VELOCITY = -1600.0
const ACCELERATION = 4000.0
const FRICTION = 4000.0
const GRAVITY = 3200.0
const FAST_FALL_GRAVITY = 3500.0

# Дополнительные параметры
const COYOTE_TIME = 0.08
const JUMP_BUFFER = 0.12
const MAX_FALL_SPEED = 1400.0

# Состояния
enum State { IDLE, WALK, JUMP, FALL }
var player_state: State = State.IDLE
var eye_state = 0

@onready var camera: Camera2D = get_viewport().get_camera_2d()

# Таймеры
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal_movement(delta)
	_handle_jump()
	_update_state()
	
	var prev = global_position
	
	move_and_slide()
	
	camera.position = camera.position - global_position + prev
	
	camera.position = camera.position.lerp(Vector2.ZERO, 1.0 - exp(-10.0 * delta))

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
	
	if input_axis != 0:
		# МГНОВЕННОЕ ускорение
		velocity.x = move_toward(velocity.x, SPEED * input_axis, ACCELERATION * delta)
		
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = input_axis < 0
	else:
		# Быстрое торможение
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

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
	if not is_on_floor():
		if velocity.y < 0:
			player_state = State.JUMP
		else:
			player_state = State.FALL
	elif abs(velocity.x) > 10:
		player_state = State.WALK
	else:
		player_state = State.IDLE

func get_state_name() -> String:
	match player_state:
		State.IDLE: return "idle"
		State.WALK: return "walk"
		State.JUMP: return "jump"
		State.FALL: return "fall"
		_: return "idle"

func die():
	# Загружаем данные последнего чекпоинта
	var checkpoint = GameManager.get_checkpoint_data()

	if checkpoint.is_empty():
		get_tree().reload_current_scene()  # Перезапуск уровня
	else:
		# Восстанавливаем состояние
		global_position = checkpoint["position"]
		eye_state = checkpoint["eyes"]
