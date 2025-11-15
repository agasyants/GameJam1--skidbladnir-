# GameManager.gd
extends Node

var current_checkpoint_data = {}

func set_checkpoint(id: String, position: Vector2, eyes: int, lens:int):
	current_checkpoint_data = {
		"id": id,
		"position_x": position.x,
		"position_y": position.y,
		"eyes": eyes,
		"len": lens
	}
	print("Checkpoint saved: ", id, " ", position, " ", eyes, " ", lens)
	SaveManager.save(current_checkpoint_data)

func get_checkpoint_data():
	return current_checkpoint_data
