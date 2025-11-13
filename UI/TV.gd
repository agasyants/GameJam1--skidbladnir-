extends ColorRect

# Ссылка на материал с шейдером
@onready var shader_material: ShaderMaterial = material

# Длительность эффекта помех
@export var static_duration: float = 0.4

# Текущее состояние
var is_showing_static: bool = false
var static_timer: float = 0.0

func _ready():
	# Изначально эффект выключен
	set_static_enabled(false)

func _process(delta):
	# Если идет анимация помех
	if is_showing_static:
		static_timer -= delta
		
		# Постепенно уменьшаем интенсивность помех
		var progress = static_timer / static_duration
		shader_material.set_shader_parameter("channel_switch_progress", progress)
		
		if static_timer <= 0.0:
			is_showing_static = false
			set_static_enabled(false)

# Включить/выключить эффект
func set_static_enabled(enabled: bool):
	visible = enabled
	if shader_material:
		shader_material.set_shader_parameter("noise_strength", 0.8 if enabled else 0.0)

# Показать эффект переключения канала
func show_channel_switch():
	is_showing_static = true
	static_timer = static_duration
	set_static_enabled(true)
	
	# Можно добавить звук помех
	$StaticSound.play()
