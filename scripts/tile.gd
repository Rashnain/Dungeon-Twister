class_name Tile extends Sprite2D


static func get_texture_from_id(id: int) -> Resource:
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
			file_name = prefix + "_four_ways"
		1:
			file_name = prefix + "_corridor"
		2:
			file_name = prefix + "_dead_end"
		3:
			file_name = prefix + "_three_ways"
		4:
			file_name = prefix + "_corner"

	return load("res://assets/tiles/%s.png" % file_name)
