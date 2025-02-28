extends Node2D


@onready var player_chooser : HSlider = $PlayerChooser


func _ready() -> void:
	if Game.nr_players:
		player_chooser.value = Game.nr_players


func _on_start_button_pressed() -> void:
	Game.nr_players = int(player_chooser.value)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
