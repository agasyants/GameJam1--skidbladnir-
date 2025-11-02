extends Node2D
class_name PlayerProxy

@export var camera: Camera2D
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")

func _ready():
	if camera:
		camera.current = false  # выключаем, включит LensManager при активации линзы

func _physics_process(delta: float) -> void:
	if player:
		global_position = player.global_position
