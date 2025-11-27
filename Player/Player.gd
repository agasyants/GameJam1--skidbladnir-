extends CharacterBody2D
class_name Player

# Константы движения
const SPEED = 600.0
const JUMP_VELOCITY = -1500.0
const ACCELERATION = 4000.0
const FRICTION = 5000.0
const GRAVITY = 3400.0
const FAST_FALL_GRAVITY = 3500.0

# Дополнительные параметры
const COYOTE_TIME = 0.08
const JUMP_BUFFER = 0.12
const STUCK_TIME = 8.0
const MAX_FALL_SPEED = 1400.0
const STUCK_CHECK_INTERVAL = 0.1

# Состояния
enum State { IDLE, WALK, JUMP, FALL }
var player_state: State = State.IDLE
var eye_state = 0

# Таймеры
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var stuck_timer = 0.0
var active_timer = 0.0
var inv_timer := 0.0
var stuck_check_timer := 0.0

var active := true
var in_transition := false
var stuck := false

# Кеш
var cached_on_floor := false
var animation_cache := {}

@onready var animation_player = $AnimationPlayer
@onready var viniet = get_tree().get_first_node_in_group("V")
@onready var lens:LensManager = get_tree().get_first_node_in_group("manager")
@onready var tv = get_node("/root/Root/Post/TVRect")

func play_change_sound():
	$Switch.play()

func _ready() -> void:
	# Предварительно кешируем строки анимаций
	for i in range(3):
		var state = str(i)
		animation_cache[i] = {
			"idle": "idle" + state,
			"walk": "walk" + state,
			"jump": "jump" + state,
			"fall": "fall" + state,
			"dead": "dead" + state
		}
	
	var loaded = GameManager.get_checkpoint_data()
	if loaded:
		eye_state = int(loaded["eyes"])
		global_position = Vector2(loaded["position_x"], loaded["position_y"])
	else:
		GameManager.set_checkpoint("str", global_position, eye_state, 0)
	
	lens.set_cameras_positions(global_position)

func _physics_process(delta: float) -> void:
	cached_on_floor = is_on_floor()
	
	if inv_timer > 0.0:
		inv_timer -= delta
		if inv_timer <= 0.0:
			inv_timer = 0
			active = true
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		_update_state()
		return  # Early return
	
	if not active:
		if active_timer < 0 and inv_timer == 0:
			death()
		active_timer -= delta
		return
	
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_horizontal_movement(delta)
	_handle_jump()
	_update_state()
	
	if not in_transition:
		move_and_slide()
	_check_stuck(delta)
	_update_stuck(delta)

# Оптимизированная проверка застревания
func _check_stuck(delta: float) -> void:
	stuck_check_timer += delta
	if stuck_check_timer < STUCK_CHECK_INTERVAL:
		return
	
	stuck_check_timer = 0.0
	stuck = test_move(global_transform, Vector2.ZERO)

func _update_stuck(delta):
	if stuck:
		stuck_timer += delta
		viniet.set_intensity(stuck_timer / STUCK_TIME)
		viniet.set_center(lens.get_head())
		viniet.set_size1(1.1 - stuck_timer / STUCK_TIME * 0.7)
		if stuck_timer > STUCK_TIME:
			die()
			stuck_check_timer = 0.0
			stuck_timer = 0.0
	else:
		viniet.set_intensity(0.0)
		viniet.set_center(lens.get_head())
		viniet.set_size1(1.2)
		stuck_timer = 0.0

func _apply_gravity(delta: float) -> void:
	if not cached_on_floor:
		var current_gravity = FAST_FALL_GRAVITY if velocity.y > 0 else GRAVITY
		velocity.y = minf(velocity.y + current_gravity * delta, MAX_FALL_SPEED)
	elif velocity.y > 0:
		velocity.y = 0

func _handle_horizontal_movement(delta: float) -> void:
	var input_axis = Input.get_axis("ui_left", "ui_right")
	
	if input_axis != 0:
		var current_accel = ACCELERATION * (1.0 if cached_on_floor else 0.8)
		velocity.x = move_toward(velocity.x, SPEED * input_axis, current_accel * delta)
		$Sprite2D.flip_h = input_axis < 0
	else:
		var current_friction = FRICTION * (1.0 if cached_on_floor else 0.4)
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	
	var can_jump = cached_on_floor or coyote_timer > 0
	
	if can_jump and jump_buffer_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.4

func _update_timers(delta: float) -> void:
	coyote_timer = COYOTE_TIME if cached_on_floor else coyote_timer - delta
	jump_buffer_timer = maxf(0, jump_buffer_timer - delta)

func _update_state() -> void:
	var anim_set = animation_cache[mini(eye_state, 2)]
	
	if not cached_on_floor:
		if velocity.y < 0:
			if player_state != State.JUMP:
				player_state = State.JUMP
				animation_player.play(anim_set["jump"])
		else:
			if player_state != State.FALL:
				player_state = State.FALL
				animation_player.play(anim_set["fall"])
	elif absf(velocity.x) > 10:
		if player_state == State.FALL:
			$Landing.play()
		if player_state != State.WALK:
			player_state = State.WALK
			animation_player.play(anim_set["walk"])
	else:
		if player_state == State.FALL:
			$Landing.play()
		if player_state != State.IDLE:
			player_state = State.IDLE
			animation_player.play(anim_set["idle"])

func get_state_name() -> String:
	match player_state:
		State.IDLE: return "idle"
		State.WALK: return "walk"
		State.JUMP: return "jump"
		State.FALL: return "fall"
		_: return "idle"

func die():
	if active and inv_timer <= 0:
		active = false
		active_timer = 0.6
		var anim_set = animation_cache[mini(eye_state, 2)]
		animation_player.play(anim_set["dead"])

func death():
	if inv_timer <= 0:
		tv.show_channel_switch()
		stuck = false
		_update_stuck(0)
		var checkpoint = GameManager.get_checkpoint_data()
		if checkpoint.is_empty():
			active = true
			get_tree().reload_current_scene()
		else:
			var l = lens.lens_names[int(checkpoint["len"])]
			if lens.lens_names[lens.current_lens] != l:
				lens.switch_lens_instant(l)
			global_position = Vector2(checkpoint["position_x"], checkpoint["position_y"])
			eye_state = int(checkpoint["eyes"])
			inv_timer = 0.5
			lens.set_cameras_positions(global_position)
