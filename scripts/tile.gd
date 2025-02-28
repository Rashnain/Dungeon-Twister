class_name Tile extends Sprite2D


static var node2d: Node2D


static func create_buttons(id: int, camera: Camera2D, game: Node2D) -> void :
	node2d = Node2D.new()
	camera.add_child(node2d)
	var x := -645
	for i in len(Game.players_tiles[id]):
		var tile_id = Game.players_tiles[id][i]
		var tile = TextureButton.new()
		if tile_id < 5:
			tile.texture_normal = load("res://assets/tiles/%s.png" % [get_background_from_id(tile_id)])
		else:
			tile.texture_normal = TextureOverlapper.overlap_str("tiles/%s" % [get_background_from_id(tile_id)], "tiles/%s" % [get_foreground_from_id(tile_id)])
		tile.position = Vector2(x, -50)
		node2d.add_child(tile)
		x += 105
		tile.pressed.connect(game._on_button_pressed.bind("%d" % i))


static func remove_buttons() -> void :
	node2d.queue_free()


static func get_foreground_from_id(id: int) -> String:
	match id:
		5, 6, 7, 8, 9:
			return "demon"
		10, 11, 12, 13, 14:
			return "spikes"
		15, 16, 17, 18, 19:
			return "tunnel"
		20, 21, 22, 23, 24:
			return "goblin"
		25, 26, 27, 28, 29:
			return "treasure"

	return "question_mark"


static func get_background_from_id(id: int) -> String:
	match id % 5:
		0:
			return "empty_four_ways"
		1:
			return "empty_corridor"
		2:
			return "empty_corner"
		3:
			return "empty_dead_end"

	return "empty_three_ways"
