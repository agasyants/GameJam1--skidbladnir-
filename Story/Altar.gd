extends Area2D

func _ready():
	var save = SaveManager.load_file()
	if save and save["eyes"] > from:
		reveal()
	else:
		body_entered.connect(_on_body_entered)

@export var from: int = 0
@export var to: int = 1
@export var backname: String = "Back-02"

@onready var lens: LensManager = get_tree().get_first_node_in_group("manager")

func reveal():
	hide()
	var back = get_parent().get_node(backname)
	if back:
		back.show()
	

func _on_body_entered(body):
	if body.is_in_group("Player"):
		reveal()
		if body.eye_state == from:
			if from == 0:
				MusicManager.world_tracks["normal"] = preload("res://Music/NormalV3.ogg")
				$Alt1.play()
			if from == 1:
				$Alt2.play()
			if from == 2:
				MusicManager.world_tracks["normal"] = preload("res://Music/End.ogg")
				MusicManager.world_tracks["echo"] = preload("res://Music/End.ogg")
				MusicManager.world_tracks["visceral"] = preload("res://Music/End.ogg")
				MusicManager.fade_out_and_restart(3.5)
				$Alt3.play()
			body.eye_state = to
			GameManager.set_checkpoint("altar", body.global_position, body.eye_state, lens.current_lens)
			
