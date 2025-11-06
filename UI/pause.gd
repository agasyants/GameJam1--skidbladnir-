extends Control

var volume_bus_name: String = "Music"
var sfx_bus_name: String = "SFX"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$resume_btn.pressed.connect(_on_resume_button_pressed)
	$restart_btn.pressed.connect(_on_restart_button_pressed)
	hide()

	# Загрузка сохраненных настроек
	var volume_data = SaveManager.load_file(volume_bus_name + '.json')
	var sfx_data = SaveManager.load_file(sfx_bus_name + '.json')
	$volume_slider.value = 0.8
	$sfx_slider.value = 0.6
	
	if volume_data:
		$volume_slider.value = volume_data["volume"]
	if sfx_data:
		$sfx_slider.value = sfx_data["sfx"]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			resume()
		else:
			get_tree().paused = true
			show()
		get_viewport().set_input_as_handled()

func _on_resume_button_pressed():
	resume()

func _on_restart_button_pressed():
	SaveManager.delete_save_file()
	GameManager.current_checkpoint_data = {}
	resume()
	MusicManager.world_tracks = {
		"normal": preload("res://Music/NormalV3.ogg"),
		"echo": preload("res://Music/EchoV2.ogg"),
		"visceral": preload("res://Music/VisceralV2.ogg"),
		"truth": preload("res://Music/VisceralV2.ogg"),
	}
	MusicManager.fade_out_and_restart(3.0)
	get_tree().reload_current_scene()

func resume():
	get_tree().paused = false
	hide()


func _on_volume_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(volume_bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	SaveManager.save({"volume": value}, volume_bus_name + '.json')


func _on_sfx_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(sfx_bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	SaveManager.save({"sfx": value}, sfx_bus_name + '.json')
