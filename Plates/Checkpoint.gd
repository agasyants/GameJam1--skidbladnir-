extends Area2D

# Уникальный ID чекпоинта
@export var checkpoint_id: String = "default"
@onready var lens: LensManager = get_tree().get_first_node_in_group("manager")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player") and body.inv_timer <= 0.0:
		activate_checkpoint(body)

func activate_checkpoint(player:Player):
	if GameManager.get_checkpoint_data() and GameManager.get_checkpoint_data()["id"] != checkpoint_id:
		GameManager.set_checkpoint(
			checkpoint_id,
			global_position,
			player.eye_state,
			lens.target_lens
		)
	
	#if has_node("AnimationPlayer"):
		#$AnimationPlayer.play("activate")
	
	# Отключаем дальнейшие активации
	#if has_node("CollisionShape2D"):
		#$CollisionShape2D.set_deferred("disabled", true)
