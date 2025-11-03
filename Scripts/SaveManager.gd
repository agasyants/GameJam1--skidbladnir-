extends Node

var save_path = "user://savegame.json"

func save_game(data: Dictionary) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file = null

func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file = null
		var json = JSON.new()
		var parse_result = json.parse(json_str)
		if parse_result == OK:
			return json.data
	return {}
