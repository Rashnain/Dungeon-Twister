extends Node2D


@onready var stats : Label = %Stats
@onready var instructions : Label = %Instructions
@onready var d4_button : Button = %Die4Button
@onready var d6_button : Button = %Die6Button

var busy := false


func _ready() -> void:
	Game.init_arrays()
	update_stats()


func _process(_delta: float) -> void:
	if busy: return
	busy = true

	for i in Game.nr_players:
		instructions.text = "It is Player %d's turn\n" % [i+1]
		if not Game.players_skip_next_turn[i]:
			# Tiles / cards
			d6_button.visible = true
			await d6_button.button_up
			d6_button.visible = false
			var die_value := d6()
			instructions.text += "Player %d got %d tile(s)" % [i+1, die_value]
			# Movement
			d4_button.visible = true
			await d4_button.button_up
			d4_button.visible = false
			die_value = d4()
			instructions.text += " and %d move(s)" % [die_value]
			# TODO add tiles to player (from the deck)
			update_stats()
			await get_tree().create_timer(1.5).timeout

	busy = false


func update_stats() -> void:
	var players_str = ""
	for i in Game.nr_players:
		players_str += "Player %d : %d coins\n" % [i+1, Game.players_money[i]]
	stats.text = players_str


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func d4() -> int:
	return randi_range(1, 4)


func d6() -> int:
	return randi_range(1, 6)
