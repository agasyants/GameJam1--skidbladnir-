extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

@export var offset := Vector2(0, -140)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var tween = create_tween()
		var a = body.camera_offset
		tween.tween_method(body.set_camera_offset, a, offset, 1.0)
