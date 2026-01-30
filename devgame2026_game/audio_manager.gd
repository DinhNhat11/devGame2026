# audio_manager.gd
# Centralized audio manager for all game sounds.
# Set up as Autoload: Project → Project Settings → Globals → Add as "AudioManager"
#
# Usage from any script:
#   AudioManager.play_boat_engine()    - when boat starts moving
#   AudioManager.stop_boat_engine()    - when boat stops moving
#   AudioManager.play_mouse_rescued()  - when a mouse is saved
#   AudioManager.play_fuel_alarm()     - when fuel is low
#   AudioManager.stop_fuel_alarm()     - when fuel is restored
#   AudioManager.play_water_ambient()  - when gameplay starts
#   AudioManager.stop_water_ambient()  - when gameplay ends
#   AudioManager.on_game_start()       - call in GameManager.start_game()
#   AudioManager.on_game_over()        - call in GameManager.end_game()

extends Node

# === AUDIO PLAYERS ===
var bg_music_player: AudioStreamPlayer
var boat_engine_player: AudioStreamPlayer
var water_ambient_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer

# One-shot SFX pool
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 4

# === AUDIO STREAMS ===
var bg_music_stream = preload("res://audio/background.mp3")
var boat_engine_stream = preload("res://audio/boat_on_river.mp3")
var water_ambient_stream = preload("res://audio/water_sound.mp3")
var alarm_stream = preload("res://audio/alarm_sound.mp3")
var mouse_rescued_stream = preload("res://audio/mouse_sound.mp3")

# === SETUP ===

func _ready():
	bg_music_player = _create_looping_player(bg_music_stream, -10.0, true)
	boat_engine_player = _create_looping_player(boat_engine_stream, -8.0, false)
	water_ambient_player = _create_looping_player(water_ambient_stream, -15.0, false)
	alarm_player = _create_looping_player(alarm_stream, -5.0, false)

	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.volume_db = -5.0
		add_child(player)
		sfx_players.append(player)

	print("AudioManager initialized!")

func _create_looping_player(stream: AudioStream, volume: float, autoplay: bool) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.finished.connect(func(): player.play())
	if autoplay:
		player.play()
	return player

# === BACKGROUND MUSIC ===

func play_bg_music():
	if not bg_music_player.playing:
		bg_music_player.play()

func stop_bg_music():
	bg_music_player.stop()

func set_bg_music_volume(db: float):
	bg_music_player.volume_db = db

# === BOAT ENGINE ===

func play_boat_engine():
	if not boat_engine_player.playing:
		boat_engine_player.play()

func stop_boat_engine():
	boat_engine_player.stop()

# === WATER AMBIENT ===

func play_water_ambient():
	if not water_ambient_player.playing:
		water_ambient_player.play()

func stop_water_ambient():
	water_ambient_player.stop()

# === FUEL ALARM ===

func play_fuel_alarm():
	if not alarm_player.playing:
		alarm_player.play()

func stop_fuel_alarm():
	alarm_player.stop()

# === ONE-SHOT SFX ===

func play_mouse_rescued():
	_play_sfx(mouse_rescued_stream)

func _play_sfx(stream: AudioStream, volume: float = -5.0):
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume
			player.play()
			return
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = volume
	sfx_players[0].play()

# === GAME STATE HELPERS ===

func on_game_start():
	play_bg_music()
	play_water_ambient()

func on_game_over():
	stop_boat_engine()
	stop_fuel_alarm()
	set_bg_music_volume(-20.0)

func on_game_restart():
	stop_fuel_alarm()
	stop_boat_engine()
	stop_water_ambient()
	set_bg_music_volume(-10.0)
