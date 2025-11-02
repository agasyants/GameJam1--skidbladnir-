extends CharacterBody2D
class_name Player

const SPEED = 600.0
const JUMP_VELOCITY = -700.0
const ACCELERATION = 1500.0
const FRICTION = 5000.0
var gravity = 1200

var eye_state = 0
var player_state = 0
# 0 - idle; 1 - walk; 2 - jump

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		player_state = 2
		velocity.y += gravity * delta

	# Движение по X
	var input_axis = Input.get_axis("ui_left", "ui_right")
	if input_axis != 0:
		player_state = 1
		velocity.x = move_toward(velocity.x, SPEED * input_axis, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if is_on_floor():
			player_state = 0

	# Прыжок
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		player_state = 2
		
	move_and_slide()
