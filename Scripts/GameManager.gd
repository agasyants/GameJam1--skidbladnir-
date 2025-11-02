# GameManager.gd
extends Node

var current_checkpoint_data = {}

func set_checkpoint(id: String, position: Vector2, eyes: int):
	current_checkpoint_data = {
		"id": id,
		"position": position,
		"eyes": eyes
	}
	print("Checkpoint saved: ", id)
	# Дополнительно: сохраняем в файл
	SaveManager.save_game(current_checkpoint_data)

func get_checkpoint_data():
	return current_checkpoint_data
