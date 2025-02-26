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
			match die_value:
				1:
					for j in 1:
						Game.draw_card(i)
					instructions.text += "They got 1 card"
				2:
					for j in 2:
						Game.draw_card(i)
					instructions.text += "They got 2 cards"
				3:
					for j in 2:
						Game.draw_tile(i)
					instructions.text += "They got 2 tiles"
				4:
					for j in 3:
						Game.draw_tile(i)
					instructions.text += "They got 3 tiles"
				_:
					for j in 1:
						Game.draw_tile(i)
					instructions.text += "They got 1 tile"
			# Movement
			d4_button.visible = true
			await d4_button.button_up
			d4_button.visible = false
			die_value = d4()
			instructions.text += " and %d move(s)" % [die_value]
			instructions.text += "\nCards : %s" % str(Game.players_cards[i])
			instructions.text += "\nTiles : %s" % str(Game.players_tiles[i])
			update_stats()
			await get_tree().create_timer(3.0).timeout

	busy = false


func update_stats() -> void:
	var players_str = ""
	for i in Game.nr_players:
		players_str += "Player %d : %d coins" % [i+1, Game.players_money[i]]
		players_str += " [Skip next turn] " if Game.players_skip_next_turn[i] else ""
		players_str += " [Treasure boost] " if Game.players_has_treasure_boost[i] else ""
		players_str += " [Cancel next trap] " if Game.players_can_cancel_traps[i] else ""
		players_str += "\n"
	stats.text = players_str


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func d4() -> int:
	return randi_range(1, 4)


func d6() -> int:
	return randi_range(1, 6)
