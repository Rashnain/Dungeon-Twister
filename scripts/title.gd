extends Node2D


@onready var player_chooser: HSlider = $PlayerChooser


func _ready() -> void:
	if GD.nr_players:
		player_chooser.value = GD.nr_players


func _on_start_button_pressed() -> void:
	GD.nr_players = int(player_chooser.value)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
