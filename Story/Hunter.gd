extends Node2D
class_name Enemy

@export var speed: float = 460.0
@export var aim_time: float = 0.85
@export var charge_min_distance: float = 500.0
@export var charge_duration: float = 0.7  # Время всего рывка

var player: Node2D
var state: String = "AIMING"
var state_timer: float = 0.0
var aim_direction: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var hitbox: Area2D
var charge_distance_traveled: float = 0.0
var charge_progress: float = 0.0  # 0..1 — прогресс рывка

var start: Vector2
var active := false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	sprite = $Sprite2D if has_node("Sprite2D") else null
	hitbox = $Hitbox if has_node("Hitbox") else null
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	change_state("AIMING")
	start = global_position

func _physics_process(delta):
	if active:
		state_timer -= delta
		global_position += (player.global_position - global_position).normalized()*2
		match state:
			"AIMING":
				handle_aiming(delta)
			"CHARGING":
				handle_charging(delta)

func handle_aiming(_delta):
	if player:
		aim_direction = (player.global_position - global_position).normalized()
	if state_timer <= 0:
		change_state("CHARGING")

func handle_charging(delta):
	# Compute charge progress (0..1)
	charge_progress += delta / charge_duration
	var t = clamp(charge_progress, 0.0, 1.0)
	
	# Easing function: smoothstep (ускорение и замедление)
	var eased_t = t * t * (3.0 - 2.0 * t)
	
	# Distance based on easing
	var distance = charge_min_distance * eased_t
	var move_distance = distance - charge_distance_traveled
	charge_distance_traveled = distance
	
	global_position += aim_direction * move_distance * (speed / charge_min_distance)
	
	if t >= 1.0:
		change_state("AIMING")

func change_state(new_state: String):
	state = new_state
	
	match state:
		"AIMING":
			state_timer = aim_time
			$Kaka.hide()
			$"Kaka-chardge".show()
		"CHARGING":
			charge_distance_traveled = 0.0
			charge_progress = 0.0
			$Kaka.show()
			$"Kaka-chardge".hide()
	
	if sprite and aim_direction.length() > 0:
		sprite.flip_h = aim_direction.x < 0

func _on_hitbox_body_entered(body):
	if body.is_in_group("Player"):
		kill_player(body)

func _on_hitbox_area_entered(area):
	if area.is_in_group("Player"):
		kill_player(area)

func kill_player(player_node):
	global_position = start
	state = "AIMING"
	active = false
	player_node.die()
