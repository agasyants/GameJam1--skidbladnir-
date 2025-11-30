# MusicManager.gd
extends Node

# --- Константы и Настройки ---
const FADE_TIME = 0.01
const DEFAULT_VOLUME_DB = 0.0
const SILENT_VOLUME_DB = -80.0

# Словарь для легкого доступа к трекам по названию
var world_tracks = {
	"normal": preload("res://Music/NormalV2.ogg"),
	"echo": preload("res://Music/EchoV2.ogg"),
	"visceral": preload("res://Music/VisceralV2.ogg"),
	"truth": preload("res://Music/VisceralV2.ogg"),
}

# --- Узлы ---
@onready var player_a: AudioStreamPlayer = $MusicPlayer1
@onready var player_b: AudioStreamPlayer = $MusicPlayer2

var current_player: AudioStreamPlayer 
var standby_player: AudioStreamPlayer 

var current_track_name = ""
var fade_tween: Tween  # Переиспользуем tween

func _ready():
	# Инициализация: Оба плеера начинают с нулевой громкости
	player_a.volume_db = SILENT_VOLUME_DB
	player_b.volume_db = SILENT_VOLUME_DB
	player_a.bus = "Music"
	player_b.bus = "Music"
	
	current_player = player_a
	standby_player = player_b
	
	play_world_music("normal")

func play_world_music(track_name: String):
	if current_track_name == track_name:
		return

	var new_stream = world_tracks.get(track_name)
	if new_stream == null:
		push_error("Трек для мира '%s' не найден." % track_name)
		return

	current_track_name = track_name

	# 1. Получаем текущую позицию воспроизведения
	var playback_position = current_player.get_playback_position()

	# 2. Настройка нового плеера
	standby_player.stream = new_stream
	standby_player.volume_db = SILENT_VOLUME_DB 

	# 3. Синхронизация: Включаем новый трек с полученной позицией
	standby_player.play(playback_position)

	# 4. Кроссфейд - используем ОДИН tween с параллельными эффектами
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_parallel(true)  # Параллельное выполнение эффективнее
	fade_tween.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, FADE_TIME)
	fade_tween.tween_property(standby_player, "volume_db", DEFAULT_VOLUME_DB, FADE_TIME)

	await fade_tween.finished

	# 5. Очистка и смена ролей
	current_player.stop()
	current_player.stream = null

	# Swap
	var temp_player = current_player
	current_player = standby_player
	standby_player = temp_player

func fade_out_and_restart(fade_duration: float = FADE_TIME):
	# Убиваем предыдущий tween
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# 1. Плавное затухание
	fade_tween = create_tween()
	fade_tween.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	
	await fade_tween.finished
	
	# 2. Перезапуск
	current_player.stop()
	current_player.stream = world_tracks.get("normal")
	current_player.play(0.0)
	
	# 3. Плавное нарастание
	fade_tween = create_tween()
	fade_tween.tween_property(current_player, "volume_db", DEFAULT_VOLUME_DB, 0.01)

func fade_out(fade_duration: float = FADE_TIME):
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	
	await fade_tween.finished
	current_player.stop()
	current_track_name = ""
