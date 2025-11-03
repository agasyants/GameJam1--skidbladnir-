# Скрипт для анимации шейдерных параметров
extends ColorRect

@onready var shader_material = material as ShaderMaterial

func _ready():
	animate_vignette()

func animate_vignette():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация интенсивности
	tween.tween_method(set_intensity, 0.0, 0.7, 2.0)
	
	# Анимация размера
	tween.tween_method(set_size1, 1.0, 0.6, 2.0)

func set_intensity(value: float):
	shader_material.set_shader_parameter("intensity", value)

func set_size1(value: float):
	shader_material.set_shader_parameter("size", value)
