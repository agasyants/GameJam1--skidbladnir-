extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	
@export var from: int = 0
@export var to: int = 1

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.eye_state == from:
			body.eye_state = to
