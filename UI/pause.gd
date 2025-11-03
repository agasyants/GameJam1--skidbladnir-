extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$resume_btn.pressed.connect(_on_resume_button_pressed)
	$restart_btn.pressed.connect(_on_restart_button_pressed)
	hide()

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
	resume()
	get_tree().reload_current_scene()

func resume():
	get_tree().paused = false
	hide()
