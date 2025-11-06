extends ColorRect

@onready var shader_material = material as ShaderMaterial

func set_intensity(value: float):
	if value > 0.0:
		shader_material.set_shader_parameter("intensity", value)
		visible = true
	else:
		visible = false

func set_size1(value: float):
	shader_material.set_shader_parameter("size", value)
