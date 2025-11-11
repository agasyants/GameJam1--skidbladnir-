extends Area2D
class_name CameraZone

func _ready():
	add_to_group("CameraZone")
	body_entered.connect(_on_body_entered)
	call_deferred("_check_initial_overlap")

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
	
	# Offset tween
	var tween1 = create_tween()
	tween1.tween_method(lens.set_camera_offset, lens.camera_offset, offset, 1.2).set_ease(Tween.EASE_IN_OUT)
	
	# Zoom tween
	var tween2 = create_tween()
	tween2.tween_method(lens.set_camera_zoom, lens.zoom, zoom, 1.4).set_ease(Tween.EASE_IN_OUT)
	
	# Получаем текущую позицию камеры
	var current_cam_pos = lens.cameras[lens.current_lens].global_position

	var has_any_limit = use_limit_left or use_limit_right or use_limit_top or use_limit_bottom

	if has_any_limit:
		var tween3 = create_tween().set_parallel(true)

		# Стартовые значения = текущая позиция камеры (или старый лимит, если он ближе)
		if use_limit_left:
			var start_left = max(lens.limit_left, current_cam_pos.x) if lens.use_limit_left else current_cam_pos.x
			tween3.tween_method(
				func(val): lens.set_limit_left(val, true),
				start_left,
				limit_left,
				limit_transition_duration
			).set_ease(Tween.EASE_IN_OUT)
		else:
			lens.use_limit_left = false
		
		if use_limit_right:
			var start_right = min(lens.limit_right, current_cam_pos.x) if lens.use_limit_right else current_cam_pos.x
			tween3.tween_method(
				func(val): lens.set_limit_right(val, true),
				start_right,
				limit_right,
				limit_transition_duration
			).set_ease(Tween.EASE_IN_OUT)
		else:
			lens.use_limit_right = false
		
		if use_limit_top:
			var start_top = max(lens.limit_top, current_cam_pos.y) if lens.use_limit_top else current_cam_pos.y
			tween3.tween_method(
				func(val): lens.set_limit_top(val, true),
				start_top,
				limit_top,
				limit_transition_duration
			).set_ease(Tween.EASE_IN_OUT)
		else:
			lens.use_limit_top = false
		
		if use_limit_bottom:
			var start_bottom = min(lens.limit_bottom, current_cam_pos.y) if lens.use_limit_bottom else current_cam_pos.y
			tween3.tween_method(
				func(val): lens.set_limit_bottom(val, true),
				start_bottom,
				limit_bottom,
				limit_transition_duration
			).set_ease(Tween.EASE_IN_OUT)
		else:
			lens.use_limit_bottom = false
	else:
		lens.disable_all_limits()
