extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

@export var offset := Vector2(0, -140)
@export var zoom := Vector2(1, 1)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var tween1 = create_tween()
		var a = body.camera_offset
		tween1.tween_method(body.set_camera_offset, a, offset, 1.2).set_ease(Tween.EASE_IN_OUT)
		var tween2 = create_tween()
		var b = body.camera.zoom
		tween2.tween_method(body.set_camera_zoom, b, zoom, 1.4).set_ease(Tween.EASE_IN_OUT)
