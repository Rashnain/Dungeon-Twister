extends Node2D


@onready var player_chooser : HSlider = $PlayerChooser


func _on_play_button_pressed() -> void:
	Game.nr_players = player_chooser.value
	get_tree().change_scene_to_file("res://scenes/game.tscn")
