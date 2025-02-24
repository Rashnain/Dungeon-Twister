extends Node2D

@onready var stats : Label = %Stats

func _ready() -> void:
	var str = ""
	for i in Game.nr_players:
		str += "Player %d : %d coins\n" % [i+1, randi_range(10, 100)]
	stats.text = str


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
