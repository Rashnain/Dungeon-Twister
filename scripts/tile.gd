class_name Tile extends Sprite2D


static var node2d: Node2D


static func create_buttons(id: int, camera: Camera2D, game: Node2D) -> void :
	node2d = Node2D.new()
	camera.add_child(node2d)
	var x := -645
	for i in len(Game.players_tiles[id]):
		var tile_id = Game.players_tiles[id][i]
		var tile = TextureButton.new()
		tile.texture_normal = load("res://assets/tiles/%s.png" % [get_name_from_id(tile_id)])
		tile.position = Vector2(x, -50)
		node2d.add_child(tile)
		x += 105
		tile.pressed.connect(game._on_button_pressed.bind("%d" % i))


static func remove_buttons() -> void :
	node2d.queue_free()


static func get_name_from_id(id: int) -> String:
	var prefix : String
	var file_name : String

	match id:
		0, 1, 2, 3, 4:
			prefix = "empty"
		5, 6, 7, 8, 9:
			prefix = "demon"
		10, 11, 12, 13, 14:
			prefix = "spikes"
		15, 16, 17, 18, 19:
			prefix = "tunnel"
		20, 21, 22, 23, 24:
			prefix = "goblin"
		25, 26, 27, 28, 29:
			prefix = "treasure"

	match id % 5:
		0:
			file_name = prefix + "_corner"
		1:
			file_name = prefix + "_corridor"
		2:
			file_name = prefix + "_dead_end"
		3:
			file_name = prefix + "_four_ways"
		4:
			file_name = prefix + "_three_ways"

	return file_name


static func get_unknow_from_id(id: int) -> String:
	var file_name: String
	var prefix := "unknown"

	match id % 5:
		0:
			file_name = prefix + "_four_ways"
		1:
			file_name = prefix + "_corridor"
		2:
			file_name = prefix + "_dead_end"
		3:
			file_name = prefix + "_three_ways"
		4:
			file_name = prefix + "_corner"

	return file_name


static func get_unknown_atlas_coord_from_id(id: int) -> Vector2i:
	return Vector2i(id % 5, 6)
