extends Area2D
class_name CameraZone

@export var offset := Vector2(0, -140)
@export var zoom := Vector2(1, 1)

@export_group("Camera Limits")
@export var use_limit_left := false
@export var use_limit_right := false
@export var use_limit_top := false
@export var use_limit_bottom := false
@export var limit_left := 0.0
@export var limit_right := 0.0
@export var limit_top := 0.0
@export var limit_bottom := 0.0
@export var limit_transition_duration := 1.2

var active_tweens: Array[Tween] = []

func _ready():
	add_to_group("CameraZone")
	body_entered.connect(_on_body_entered)
	call_deferred("_check_initial_overlap")

func _check_initial_overlap():
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("Player"):
			_apply_camera_settings(body)
			break

func _on_body_entered(body):
	if body.is_in_group("Player"):
		_apply_camera_settings(body)

func _apply_camera_settings(body):
	var lens = body.lens
	if not is_instance_valid(lens):
		return
	
	_kill_active_tweens()
	
	# Offset tween
	var tween1 = create_tween()
	active_tweens.append(tween1)
	tween1.tween_method(lens.set_camera_offset, lens.camera_offset, offset, 1.2).set_ease(Tween.EASE_IN_OUT)
	
	# Zoom tween
	var tween2 = create_tween()
	active_tweens.append(tween2)
	tween2.tween_method(lens.set_camera_zoom, lens.zoom, zoom, 1.4).set_ease(Tween.EASE_IN_OUT)

	# Стартовые значения = текущая позиция камеры (или старый лимит, если он ближе)
	if use_limit_left:
		lens.set_limit_left(limit_left, true)
	else:
		lens.use_limit_left = false
	
	if use_limit_right:
		lens.set_limit_right(limit_right, true)
	else:
		lens.use_limit_right = false
	
	if use_limit_top:
		lens.set_limit_top(limit_top, true)
	else:
		lens.use_limit_top = false
	
	if use_limit_bottom:
		lens.set_limit_bottom(limit_bottom, true)
	else:
		lens.use_limit_bottom = false


func _kill_active_tweens():
	for tween in active_tweens:
		if is_instance_valid(tween) and tween.is_running():
			tween.kill()
	active_tweens.clear()
