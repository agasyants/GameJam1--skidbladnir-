# id: enemy_fly_unbeatable.gd
extends Node2D
# If using Godot 4, replace `Node2D` with `Node2D` (same) and keep code largely identical.

# --- exported tunables ---
@export var player_path: NodePath                                           # NodePath to the player node
@export var detection_range: float = 800.0                                  # horizontal detection range
@export var vertical_lock_tolerance: float = 120.0                           # how far vertically player can be to trigger aiming
@export var aim_delay: float = 0.35                                          # time to "aim" (player must react)
@export var charge_speed: float = 600.0                                      # horizontal speed during charge
@export var follow_vertical_speed: float = 800.0                             # vertical speed while adjusting to target Y
@export var attack_distance: float = 1200.0                                  # how far it flies during a single charge
@export var turn_duration: float = 2.2                                       # long time to "turn around"
@export var idle_speed: float = 80.0                                         # slow hovering speed when idle
@export var hover_amplitude: float = 6.0                                     # vertical wiggle when idle
@export var hover_frequency: float = 1.2                                     # vertical wiggle speed
@export var start_facing_right: bool = true                                  # initial facing

# --- internal state ---
enum State {IDLE, AIMING, CHARGING, TURNING}
var state = State.IDLE
onready var player = get_node_or_null(player_path)
var direction = 1 if start_facing_right else -1
var aim_timer = 0.0
var charge_travelled = 0.0
var target_y = 0.0
var turn_timer = 0.0
var idle_time = 0.0

func _ready():
	# Ensure we have a player reference; if not, warn in the debugger.
	if player == null:
		push_warning("Enemy: player node not set or not found. Set 'player_path' to your player node.")
	# set initial facing scale.x
	$Sprite.scale.x = abs($Sprite.scale.x) * (1 if start_facing_right else -1)

func _process(delta):
	if player == null:
		return

	match state:
		State.IDLE:
			_state_idle(delta)
		State.AIMING:
			_state_aiming(delta)
		State.CHARGING:
			_state_charging(delta)
		State.TURNING:
			_state_turning(delta)

# -----------------------------
# IDLE: slowly hover, check for player in range
func _state_idle(delta):
	# simple horizontal slow patrol/hover motion (move a bit in facing direction)
	idle_time += delta
	var hover_y = sin(idle_time * hover_frequency) * hover_amplitude
	global_position.y = global_position.y.linear_interpolate(global_position.y + hover_y, 0.15)
	global_position.x += direction * idle_speed * delta

	# Detect player in horizontal range and roughly same vertical band
	var dx = player.global_position.x - global_position.x
	var dy = abs(player.global_position.y - global_position.y)
	if abs(dx) <= detection_range and dy <= vertical_lock_tolerance and sign(dx) == direction:
		# start aiming
		state = State.AIMING
		aim_timer = 0.0
		# lock the vertical position we want to fly at so the player's feet must jump to avoid
		# we bias slightly below the player's center to force a jump
		target_y = player.global_position.y + 10.0
		# ensure we face the correct direction
		_set_facing(1 if dx > 0 else -1)

# -----------------------------
# AIMING: stay in place for a short time to "aim" at player (gives player chance to react)
func _state_aiming(delta):
	aim_timer += delta
	# smoothly approach target_y while aiming
	global_position.y = lerp(global_position.y, target_y, min(1.0, follow_vertical_speed * delta / max(1, abs(global_position.y - target_y))))
	# small subtle anticipation movement (optional)
	# when aim delay elapsed, start charging
	if aim_timer >= aim_delay:
		state = State.CHARGING
		charge_travelled = 0.0

# -----------------------------
# CHARGING: fly horizontally at charge_speed through everything, adjusting vertical to stay on target_y
func _state_charging(delta):
	# move horizontally ignoring collisions
	var step = direction * charge_speed * delta
	global_position.x += step
	charge_travelled += abs(step)
	# correct vertical to target_y smoothly
	global_position.y = move_toward(global_position.y, target_y, follow_vertical_speed * delta)

	# Condition: after we've flown at least attack_distance OR we've passed significantly beyond player's x, start turning
	var passed_player = (direction > 0 and global_position.x > player.global_position.x + 40) or (direction < 0 and global_position.x < player.global_position.x - 40)
	if charge_travelled >= attack_distance or passed_player:
		state = State.TURNING
		turn_timer = 0.0
		# freeze for a moment and optionally play turn animation (we'll rotate sprite slowly)
		# ensure sprite is visible facing the travel direction until it finishes turning

# -----------------------------
# TURNING: long, slow turnaround — vulnerable window for player interaction (but since enemy is unkillable, it's only an obstacle)
func _state_turning(delta):
	turn_timer += delta
	# animate a slow rotation to emphasize "long turning"
	# rotate sprite continuously while turning (visual only)
	var progress = clamp(turn_timer / turn_duration, 0.0, 1.0)
	$Sprite.rotation = lerp(0.0, PI, progress)  # visually flip 180 degrees during turn
	if turn_timer >= turn_duration:
		# finish turning: reset rotation, flip facing, go back to idle (or start another charge)
		$Sprite.rotation = 0.0
		direction = -direction
		_set_facing(direction)
		state = State.IDLE
		idle_time = 0.0

# -----------------------------
# Utility helpers
func _set_facing(dir: int) -> void:
	# Flip sprite horizontally by scale.x sign.
	var s = $Sprite.scale
	s.x = abs(s.x) * (1 if dir > 0 else -1)
	$Sprite.scale = s

# simple linear interpolation helper (Godot 3 has lerp)
func lerp(a, b, t):
	return a + (b - a) * t

# move_toward helper (Godot has move_toward in 4, replicate for compatibility)
func move_toward(from_val, to_val, delta):
	if abs(to_val - from_val) <= delta:
		return to_val
	return from_val + sign(to_val - from_val) * delta
