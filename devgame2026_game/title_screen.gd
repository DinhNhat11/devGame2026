extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainWorld.tscn")
	pass # Replace with function body.


func _on_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/about.tscn")
	pass # Replace with function body.
