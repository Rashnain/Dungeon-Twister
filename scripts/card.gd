class_name Card


static var container: CenterContainer


static func create_buttons(id: int, game: Node2D) -> void:
	container = game.get_node("%CardContainer")
	container.position.y = 125
	container.size.y = 185
	var hbox := container.get_node("HBoxContainer")
	for i in len(GM.players[id].cards):
		var card_id = GM.players[id].cards[i]
		var card = TextureButton.new()
		card.texture_normal = load("res://assets/cards/%s.png" % [get_name_from_id(card_id)])
		hbox.add_child(card)
		card.pressed.connect(game._on_button_pressed.bind("%d" % i))
	var nr := len(GM.players[id].cards)
	container.get_node("ColorRect").custom_minimum_size = Vector2(nr*100+(nr+1)*5, 185)
	container.get_node("ColorRect").visible = true


static func remove_buttons() -> void:
	container.get_node("ColorRect").visible = false
	for node in container.get_node("HBoxContainer").get_children():
		node.queue_free()


static func get_name_from_id(id: int) -> String:
	match id:
		0:
			return "switch"
		1:
			return "skip_player"
		2:
			return "steal_money"
		3:
			return "push"
		4:
			return "steal_card"
		5:
			return "cancel_trap"
		6:
			return "treasure_boost"
		7:
			return "insight"
		8:
			return "spawn_bandit"
		_:
			return "switch_tile"
