extends CanvasLayer
class_name LensManager

@onready var viewports = {
	"normal": $"Texture_Normal/Viewport_Normal",
	"echo": $"Texture_Echo/Viewport_Echo",
	"visceral": $"Texture_Visceral/Viewport_Visceral",
	"truth": $"Texture_Truth/Viewport_Truth"
}

var LENSES = {
	"normal": 0,
	"echo": 1,
	"visceral": 2,
	"truth": 3
}

var lens_names = ["normal", "echo", "visceral", "truth"]
var current_lens := 0
var target_lens := 0
var is_transitioning := false
var transitioning_to := "normal"
var transition_progress := 0.0
var transition_speed := 1.8

var texture_rects = {}
var transition_rect: ColorRect
var transition_material: ShaderMaterial

var player: Player
var enemy: Enemy

var cameras:Array[Camera2D] = []

# Кеш для оптимизации
var cached_viewport_size: Vector2
var head_offset := Vector2(0, -40)

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	enemy = get_tree().get_first_node_in_group("Enemy")
	cached_viewport_size = get_viewport().get_visible_rect().size
	
	# Создаём ColorRect для эффекта перехода
	transition_rect = ColorRect.new()
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.visible = false
	add_child(transition_rect)
	
	# Загружаем шейдер
	var shader = load("res://Shader/transition.gdshader")
	transition_material = ShaderMaterial.new()
	transition_material.shader = shader
	transition_rect.material = transition_material
	
	# Привязка текстур SubViewport → TextureRect
	for key in viewports:
		var viewport: SubViewport = viewports[key]
		var camera = Camera2D.new()
		viewport.add_child(camera)
		cameras.append(camera)
		var rect: TextureRect = viewport.get_parent() as TextureRect
		rect.texture = viewport.get_texture()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.visible = false
		texture_rects[key] = rect
	
	var l = GameManager.get_checkpoint_data()
	if l:
		switch_lens_instant(lens_names[int(l["len"])])
		print("aaaaaaaa:", l["len"])
	else:
		switch_lens_instant("normal")
	set_cameras_positions(player.global_position)
	
	# Подписываемся на изменение размера viewport
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	cached_viewport_size = get_viewport().get_visible_rect().size

var camera_offset := Vector2(0, -140)
var zoom := Vector2(1.0, 1.0)
var camera_frame := Rect2(0, 0, 0, 0)

# Система лимитов:
var limit_left := -100000.0
var limit_right := 100000.0
var limit_top := -100000.0
var limit_bottom := 100000.0
var target_limit_left := -100000.0
var target_limit_right := 100000.0
var target_limit_top := -100000.0
var target_limit_bottom := 100000.0
var use_limit_left := false
var use_limit_right := false
var use_limit_top := false
var use_limit_bottom := false

func set_camera_offset(_offset):
	camera_offset = _offset

func set_camera_zoom(_zoom):
	zoom = _zoom
	for camera in cameras:
		camera.zoom = _zoom

func set_cameras_positions(pos:Vector2):
	for camera in cameras:
		camera.global_position = pos

func set_limit_left(value: float, enabled: bool = true):
	if target_limit_left != value or use_limit_left != enabled:
		target_limit_left = value
		limit_left = value - 800
		use_limit_left = enabled
		progress = 0.0

func set_limit_right(value: float, enabled: bool = true):
	if target_limit_right != value or use_limit_right != enabled:
		target_limit_right = value
		limit_right = value + 800
		use_limit_right = enabled
		progress = 0.0

func set_limit_top(value: float, enabled: bool = true):
	if target_limit_top != value or use_limit_top != enabled:
		target_limit_top = value
		limit_top = value - 800
		use_limit_top = enabled
		progress = 0.0

func set_limit_bottom(value: float, enabled: bool = true):
	if target_limit_bottom != value or use_limit_bottom != enabled:
		target_limit_bottom = value
		limit_bottom = value + 800
		use_limit_bottom = enabled
		progress = 0.0

func _process(delta):
	if is_transitioning:
		transition_progress += delta * transition_speed
		if transition_progress >= 1.0:
			finish_transition()
		else:
			transition_material.set_shader_parameter("progress", transition_progress)
			# Вычисляем get_head() только если нужно
			if transition_progress < 0.95:
				transition_material.set_shader_parameter("center", get_head())
	
	if is_instance_valid(player):
		_update_camera_position(delta)

# helper easing (smootherstep gives very smooth in-out)
func ease_in_out(t: float) -> float:
	# smootherstep: very smooth in/out
	return t * t * (t * (6.0 * t - 15.0) + 10.0)

var progress := 0.0  # accumulated progress [0..1]

# Оптимизированное обновление позиции камеры
func _update_camera_position(delta: float):
	var target_pos = player.global_position + camera_offset
	var step = 1.0 - exp(-0.1 * delta)
	progress = lerp(progress, 1.0, step)
	progress = clamp(progress, 0.0, 1.0)

	# Apply in-out easing to the accumulated progress
	var lerp_factor := ease_in_out(progress)
	
	# Применяем лимиты
	if use_limit_left:
		limit_left = lerp(limit_left, target_limit_left, lerp_factor)
		target_pos.x = maxf(target_pos.x, limit_left)
	if use_limit_right:
		limit_right = lerp(limit_right, target_limit_right, lerp_factor)
		target_pos.x = minf(target_pos.x, limit_right)
	if use_limit_top:
		limit_top = lerp(limit_top, target_limit_top, lerp_factor)
		target_pos.y = maxf(target_pos.y, limit_top)
	if use_limit_bottom:
		limit_bottom = lerp(limit_bottom, target_limit_bottom, lerp_factor)
		target_pos.y = minf(target_pos.y, limit_bottom)
		
	lerp_factor = 1.0 - exp(-10.0 * delta)
	
	# Порог для остановки интерполяции
	for camera in cameras:
		var distance_sq = camera.global_position.distance_squared_to(target_pos)
		if distance_sq > 0.01:
			camera.global_position = camera.global_position.lerp(target_pos, lerp_factor)
		else:
			camera.global_position = target_pos

func _input(event: InputEvent):
	if player != null:
		if event.is_action_pressed("switch_normal"):
			switch_lens("normal")
			enemy.active = false
		if event.is_action_pressed("switch_echo") and player.eye_state > 0:
			switch_lens("echo")
			enemy.active = false
		if event.is_action_pressed("switch_visceral") and player.eye_state > 1:
			switch_lens("visceral")
			enemy.active = true
		#if event.is_action_pressed("switch_truth") and player.eye_state > 2:
			#switch_lens("truth")
		if event.is_action_pressed("restart"):
			player.death()
		if event.is_action_pressed("pause"):
			get_tree().paused = true

func switch_lens(_name: String):
	if lens_names[current_lens] == _name:
		return
	target_lens = LENSES[_name]
	if transitioning_to == _name:
		switch_lens_instant(transitioning_to)
		return
	start_transition(_name)

func switch_lens_instant(_name: String):
	# Отключаем предыдущий viewport
	var old_viewport = viewports[lens_names[current_lens]]
	print("Instant: ", lens_names[current_lens], " -> ", _name)
	old_viewport.turn_off()

	current_lens = LENSES[_name]

	# Включаем новый viewport
	var new_viewport = viewports[_name]
	transitioning_to = _name
	new_viewport.turn_on()

	if player != null:
		update_player_physics(current_lens)
		move_player_to_viewport(_name)
		
		# Проверяем Area2D в новом viewport после смены
		call_deferred("_recheck_areas")

	for key in texture_rects:
		texture_rects[key].visible = (key == _name)

	MusicManager.play_world_music(_name)

# ИСПРАВЛЕНИЕ #4: Оптимизированная проверка областей только в текущем viewport
func _recheck_areas():
	var current_viewport = viewports[lens_names[current_lens]]
	# Рекурсивно ищем CameraZone только в текущем viewport
	_recheck_areas_recursive(current_viewport)

func _recheck_areas_recursive(node: Node):
	if node is CameraZone:
		if node.has_method("_check_initial_overlap"):
			node._check_initial_overlap()
	
	for child in node.get_children():
		_recheck_areas_recursive(child)

func get_head() -> Vector2:
	if not is_instance_valid(player):
		return Vector2(0.5, 0.5)
	
	var current_camera = cameras[current_lens]
	var character_position = player.global_position + head_offset
	var camera_position = current_camera.global_position
	
	# Оптимизация вычислений
	var zoom_value = current_camera.zoom.x
	var relative_position = (character_position - camera_position) * zoom_value
	var viewport_position = relative_position + cached_viewport_size * 0.5
	
	# Используем обратное деление
	var inv_viewport_width = 1.0 / cached_viewport_size.x
	var inv_viewport_height = 1.0 / cached_viewport_size.y
	
	return Vector2(
		clampf(viewport_position.x * inv_viewport_width, 0.0, 1.0),
		clampf(viewport_position.y * inv_viewport_height, 0.0, 1.0)
	)

func start_transition(_name: String):
	player.play_change_sound()

	# Включаем ОБА viewport на время перехода
	var from_viewport = viewports[lens_names[current_lens]]
	var to_viewport = viewports[_name]
	from_viewport.turn_on()
	to_viewport.turn_on()

	is_transitioning = true
	transition_progress = 0.0
	var from_name = lens_names[current_lens]
	var to_name = _name
	transitioning_to = to_name
	
	# Кешируем текстуры
	var from_texture = from_viewport.get_texture()
	var to_texture = to_viewport.get_texture()
	var last_rotation = randf() * TAU  # TAU = 2*PI
	
	transition_material.set_shader_parameter("texture_from", from_texture)
	transition_material.set_shader_parameter("texture_to", to_texture)
	transition_material.set_shader_parameter("rotation", last_rotation)
	transition_material.set_shader_parameter("progress", 0.0)
	
	# Показываем переходный слой
	transition_rect.visible = true
	call_deferred("_recheck_areas")
	
	# Скрываем оригинальные текстуры
	for rect in texture_rects.values():
		rect.visible = false
	
	# Сразу обновляем физику игрока
	if player != null:
		update_player_physics(target_lens)
		move_player_to_viewport(to_name)
	
	MusicManager.play_world_music(to_name)
	print("Transition: ", from_name, " -> ", to_name)

func finish_transition():
	is_transitioning = false
	transition_rect.visible = false

	# ВАЖНО: отключаем старый viewport
	var old_viewport = viewports[lens_names[current_lens]]
	old_viewport.turn_off()

	current_lens = target_lens
	var lens_name = lens_names[current_lens]

	texture_rects[lens_name].visible = true

func update_player_physics(lens_index: int):
	player.collision_mask = 0
	player.set_collision_mask_value(lens_index + 1, true)

func move_player_to_viewport(lens_name: String):
	call_deferred("_move_player_deferred", lens_name)

func _move_player_deferred(lens_name: String):
	if not is_instance_valid(player):
		return
	
	var old_parent = player.get_parent()
	if old_parent != null:
		old_parent.remove_child(player)
	
	var target_viewport = viewports.get(lens_name)
	if target_viewport != null:
		target_viewport.add_child(player)
