extends Area2D  # или Area3D для 3D

# Сигнал для уведомления о активации (опционально)
signal checkpoint_activated

# Уникальный ID чекпоинта
@export var checkpoint_id: String = "default"

func _ready():
	# Правильное подключение сигнала в Godot 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):  # Проверяем, что это игрок
		activate_checkpoint(body)

func activate_checkpoint(player:Player):
	# Сохраняем данные в глобальном менеджере
	GameManager.set_checkpoint(
		checkpoint_id,
		global_position,
		player.eye_state
	)
	
	# Визуальный эффект (например, изменить анимацию)
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("activate")
	
	# Отключаем дальнейшие активации
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	checkpoint_activated.emit()
