extends Node2D


@onready var stats : Label = %Stats


func _ready() -> void:
	Game.init_arrays()
	update_stats()


func update_stats():
	var players_str = ""
	for i in Game.nr_players:
		players_str += "Player %d : %d coins\n" % [i+1, Game.players_money[i]]
	stats.text = players_str


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
