extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.stream = preload("res://audio/background.mp3")
	music_player.volume_db = -10
	music_player.autoplay = true
	add_child(music_player)
	
	# Loop when finished
	music_player.finished.connect(_on_music_finished)

func _on_music_finished():
	music_player.play()

func set_volume(db: float):
	music_player.volume_db = db

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false

func stop_music():
	music_player.stop()
