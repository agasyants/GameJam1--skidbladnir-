extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

@onready var enemy: Enemy = get_tree().get_first_node_in_group("enemy")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		enemy.active = false
