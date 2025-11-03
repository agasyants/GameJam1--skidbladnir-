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
var transition_progress := 0.0
var transition_speed := 1.5  # Скорость перехода

var texture_rects = {}
var transition_rect: ColorRect
var transition_material: ShaderMaterial

func _ready():
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
		var rect: TextureRect = viewport.get_parent() as TextureRect
		rect.texture = viewport.get_texture()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.visible = false
		texture_rects[key] = rect
		
		# Все viewport рендерятся всегда (для плавного перехода)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	switch_lens_instant("normal")

func _process(delta):
	if is_transitioning:
		transition_progress += delta * transition_speed
		
		if transition_progress >= 1.0:
			finish_transition()
		else:
			# Обновляем прогресс шейдера
			transition_material.set_shader_parameter("progress", transition_progress)

func _input(event: InputEvent):
	if event.is_action_pressed("switch_normal"):
		switch_lens("normal")
	if event.is_action_pressed("switch_echo"):
		switch_lens("echo")
	if event.is_action_pressed("switch_visceral"):
		switch_lens("visceral")
	if event.is_action_pressed("switch_truth"):
		switch_lens("truth")
	if event.is_action_pressed("restart"):
		var player: Player = get_tree().get_first_node_in_group("Player")
		if player != null:
			player.die()

func switch_lens(_name: String):
	if is_transitioning or lens_names[current_lens] == _name:
		return
	
	target_lens = LENSES[_name]
	start_transition(_name)

func switch_lens_instant(_name: String):
	"""Мгновенное переключение без анимации (для старта игры)"""
	current_lens = LENSES[_name]
	
	var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
	if player != null:
		update_player_physics(player, current_lens)
		move_player_to_viewport(player, _name)
	
	# Показываем только текущую линзу
	for key in texture_rects:
		texture_rects[key].visible = (key == _name)
	
	print("Instant switch to: ", _name)

func start_transition(_name: String):
	is_transitioning = true
	transition_progress = 0.0
	
	var from_name = lens_names[current_lens]
	var to_name = _name
	
	# Настраиваем шейдер
	var from_texture = viewports[from_name].get_texture()
	var to_texture = viewports[to_name].get_texture()
	
	transition_material.set_shader_parameter("texture_from", from_texture)
	transition_material.set_shader_parameter("texture_to", to_texture)
	transition_material.set_shader_parameter("progress", 0.0)
	
	# Показываем переходный слой
	transition_rect.visible = true
	
	# Скрываем оригинальные текстуры
	for key in texture_rects:
		texture_rects[key].visible = false
	
	# Сразу обновляем физику игрока
	var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
	if player != null:
		update_player_physics(player, target_lens)
		move_player_to_viewport(player, to_name)
	
	print("Starting transition: ", from_name, " -> ", to_name)

func finish_transition():
	is_transitioning = false
	transition_rect.visible = false
	
	# Обновляем текущую линзу
	current_lens = target_lens
	var lens_name = lens_names[current_lens]
	
	# Показываем финальную текстуру
	texture_rects[lens_name].visible = true
	
	print("Transition complete: ", lens_name)

func update_player_physics(player: CharacterBody2D, lens_index: int):
	player.collision_mask = 0
	player.set_collision_mask_value(lens_index + 1, true)

func move_player_to_viewport(player: CharacterBody2D, lens_name: String):
	var p = player.get_parent()
	if p != null:
		p.remove_child.call_deferred(player)
	viewports[lens_name].add_child.call_deferred(player)
