# MusicManager.gd
extends Node

# --- Константы и Настройки ---
const FADE_TIME = 0.01 # Длительность плавного перехода в секундах. Подберите под ритм музыки.
const DEFAULT_VOLUME_DB = 0.0 # Обычная громкость (0.0 - максимум без искажений)
const SILENT_VOLUME_DB = -80.0 # Громкость, которая считается "выключенной"

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


func _ready():
	# Инициализация: Оба плеера начинают с нулевой громкости и в режиме ожидания
	player_a.volume_db = SILENT_VOLUME_DB
	player_b.volume_db = SILENT_VOLUME_DB
	player_a.bus = "Music" # Убедитесь, что шина установлена
	player_b.bus = "Music"
	
	current_player = player_a
	standby_player = player_b
	
	play_world_music("normal")


func play_world_music(track_name: String):
	if current_track_name == track_name:
		return

	var new_stream = world_tracks.get(track_name)
	if new_stream == null:
		print("Ошибка: Трек для мира '%s' не найден." % track_name)
		return

	print("Синхронизированное переключение на: %s" % track_name)
	current_track_name = track_name

	# 1. ЗАПИСЬ ПОЗИЦИИ: Получаем текущую позицию воспроизведения (в секундах)
	var playback_position = current_player.get_playback_position()

	# --- 2. Настройка нового плеера (Standby) ---
	standby_player.stream = new_stream
	standby_player.volume_db = SILENT_VOLUME_DB 

	# 3. СИНХРОНИЗАЦИЯ: Включаем новый трек с полученной позицией!
	standby_player.play(playback_position)

	# --- 4. Кроссфейд (Плавное затухание/нарастание) ---

	# А) Текущий трек: Плавно затихает
	var tween_fade_out = create_tween()
	tween_fade_out.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, FADE_TIME)

	# Б) Новый трек: Плавно набирает громкость
	var tween_fade_in = create_tween()
	tween_fade_in.tween_property(standby_player, "volume_db", DEFAULT_VOLUME_DB, FADE_TIME)

	# --- 5. Смена Ролей ---
	await tween_fade_out.finished

	current_player.stop()
	current_player.stream = null

	# Меняем местами роли
	var temp_player = current_player
	current_player = standby_player
	standby_player = temp_player

# Плавно гасит музыку и начинает трек сначала
func fade_out_and_restart(fade_duration: float = FADE_TIME):
	print("Перезапуск текущего трека: %s" % current_track_name)
	
	# 1. Плавное затухание текущего плеера
	var tween_fade = create_tween()
	tween_fade.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	
	# 2. Ждем завершения затухания
	await tween_fade.finished
	
	# 3. Останавливаем и перезапускаем с начала
	current_player.stop()
	current_player.stream = world_tracks.get("normal")
	current_player.play(0.0)
	
	# 4. Плавное нарастание громкости
	var tween_fade_in = create_tween()
	tween_fade_in.tween_property(current_player, "volume_db", DEFAULT_VOLUME_DB, 0.01)

# Просто плавно гасит музыку (без перезапуска)
func fade_out(fade_duration: float = FADE_TIME):
	print("Затухание музыки")
	
	var tween_fade = create_tween()
	tween_fade.tween_property(current_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	
	await tween_fade.finished
	current_player.stop()
	current_track_name = ""
