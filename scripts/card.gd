class_name Card


static var node2d: Node2D


static func create_buttons(id: int, camera: Camera2D, game: Node2D) -> void:
	node2d = Node2D.new()
	node2d.position = Vector2(-635, 130)
	camera.add_child(node2d)
	var x := 0
	for i in len(GD.players_cards[id]):
		var card_id = GD.players_cards[id][i]
		var card = TextureButton.new()
		card.texture_normal = load("res://assets/cards/%s.png" % [get_name_from_id(card_id)])
		card.position = Vector2(x, 0)
		node2d.add_child(card)
		x += 105
		card.pressed.connect(game._on_button_pressed.bind("%d" % i))


static func remove_buttons() -> void:
	node2d.queue_free()


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
