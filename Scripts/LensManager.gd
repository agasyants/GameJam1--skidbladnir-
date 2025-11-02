extends CanvasLayer
class_name LensManager

@onready var viewports = {
	"normal": $"Texture_Normal/Viewport_Normal",
	"echo": $"Texture_Echo/Viewport_Echo",
	"visceral": $"Texture_Visceral/Viewport_Visceral",
	"truth": $"Texture_Truth/Viewport_Truth"
}

var LENSES = {
	"normal": 0,
	"echo": 1,
	"visceral": 2,
	"truth": 3
}

var lens_names = ["normal", "echo", "visceral", "truth"]
var current_lens := 0

func _ready():
	# Привязка текстур SubViewport → TextureRect
	for key in viewports:
		var viewport: SubViewport = viewports[key]
		var rect: TextureRect = viewport.get_parent() as TextureRect
		rect.texture = viewport.get_texture()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.visible = false
	switch_lens("normal")

func _input(event:InputEvent):
	if event.is_action_pressed("switch_normal"):
		switch_lens("normal")
	if event.is_action_pressed("switch_echo"):
		switch_lens("echo")
	if event.is_action_pressed("switch_visceral"):
		switch_lens("visceral")
	if event.is_action_pressed("switch_truth"):
		switch_lens("truth")

func switch_lens(name: String):
	var player: CharacterBody2D = get_tree().get_first_node_in_group("Player")
	var lens_index = LENSES[name]
	# --- 1. ПЕРЕКЛЮЧАЕМ ФИЗИКУ ИГРОКА ---
	if player != null:
		player.collision_mask = 0 
		player.set_collision_mask_value(lens_index + 1, true)
		var p = player.get_parent()
		p.remove_child.call_deferred(player)
	else:
		print(player)
	
	for key in viewports:
		var viewport: SubViewport = viewports[key]
		var rect: TextureRect = viewport.get_parent() as TextureRect
		var is_active = (key == name)
		viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if is_active else SubViewport.UPDATE_DISABLED
		)
		rect.visible = is_active
		if is_active:
			viewport.add_child.call_deferred(player)

	print("Switched lens: ", name)
