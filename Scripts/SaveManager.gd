extends Node

func save_game(data: Dictionary, save_path = "savegame.json") -> void:
	var file = FileAccess.open("user://" + save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file = null

func load_game(save_path = "savegame.json") -> Dictionary:
	if not FileAccess.file_exists("user://" + save_path):
		return {}
	var file = FileAccess.open("user://" + save_path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file = null
		var json = JSON.new()
		var parse_result = json.parse(json_str)
		if parse_result == OK:
			return json.data
	return {}

func delete_save_file(save_path = "savegame.json"):
	if FileAccess.file_exists("user://" + save_path):
		var dir = DirAccess.open("user://")
		dir.remove("user://" + save_path)
		print("Файл сохранения удален")
	else:
		print("Файл сохранения не существует")
