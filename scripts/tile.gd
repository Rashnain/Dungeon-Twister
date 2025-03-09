class_name Tile


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

enum Side { TOP, RIGHT, BOTTOM, LEFT }

static var container: CenterContainer

var top: bool
var right: bool
var bottom: bool
var left: bool


func init(p_top: bool, p_right: bool, p_bottom: bool, p_left: bool) -> void:
	top = p_top
	right = p_right
	bottom = p_bottom
	left = p_left


func rotate_90() -> void:
	var temp := top
	top = left
	left = bottom
	bottom = right
	right = temp


func is_connectable(other: Tile, side: Side) -> bool:
	match side:
		Side.TOP:
			return top and other.bottom
		Side.RIGHT:
			return right and other.left
		Side.BOTTOM:
			return bottom and other.top
		Side.LEFT:
			return left and other.right
	return false


static func create_from_id(id: int) -> Tile:
	var tile = Tile.new()
	match id:
		0:
			tile.init(1, 1, 1, 1)
		1:
			tile.init(1, 0, 1, 0)
		2:
			tile.init(1, 1, 0, 0)
		3:
			tile.init(0, 0, 1, 0)
		4:
			tile.init(1, 1, 0, 1)
	return tile


static func create_buttons(id: int, game: Node2D) -> void:
	container = game.get_node("%CardContainer")
	container.position.y = 195
	var hbox := container.get_node("HBoxContainer")
	for i in len(GM.players[id].tiles):
		var tile_id = GM.players[id].tiles[i]
		var tile = TextureButton.new()
		if tile_id < 5:
			tile.texture_normal = load("res://assets/tiles/%s.png" % [get_background_from_id(tile_id)])
		else:
			tile.texture_normal = TextureOverlapper.overlap_str("tiles/%s" % [get_background_from_id(tile_id)], "tiles/%s" % [get_foreground_from_id(tile_id)])
		hbox.add_child(tile)
		tile.pressed.connect(game._on_button_pressed.bind("%d" % i))
	var nr := len(GM.players[id].tiles)
	container.get_node("ColorRect").custom_minimum_size = Vector2(nr*100+(nr+1)*5, 110)
	container.get_node("ColorRect").visible = true


static func remove_buttons() -> void:
	container.get_node("ColorRect").visible = false
	for node in container.get_node("HBoxContainer").get_children():
		node.queue_free()


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


static func is_connectable_with_surrounding(id: int, pos: Vector2i, turns_90: int, dungeon: TileMapLayer) -> bool:
	var tile := create_from_id(id)
	for i in turns_90:
		tile.rotate_90()

	var surrounding_cells := dungeon.get_surrounding_cells(pos)
	for cell_pos in surrounding_cells:
		var neighbor_id := dungeon.get_cell_source_id(cell_pos)
		if neighbor_id > -1:
			if is_connectable_tile_pos(tile, pos, cell_pos, dungeon):
				return true

	return false


static func is_connectable_tile_pos(tile: Tile, tile_pos: Vector2i, neighbor_pos: Vector2i, dungeon: TileMapLayer) -> bool:
	var neighbor_id := dungeon.get_cell_source_id(neighbor_pos)
	var neighbor_tile := create_from_id(neighbor_id)
	match dungeon.get_cell_alternative_tile(neighbor_pos):
		TileRotation.ROTATE_90:
			neighbor_tile.rotate_90()
		TileRotation.ROTATE_180:
			for i in 2:
				neighbor_tile.rotate_90()
		TileRotation.ROTATE_270:
			for i in 3:
				neighbor_tile.rotate_90()
	var side
	var offset_pos = neighbor_pos - tile_pos
	match offset_pos:
		Vector2i(0, -1):
			side = Side.TOP
		Vector2i(1, 0):
			side = Side.RIGHT
		Vector2i(0, 1):
			side = Side.BOTTOM
		Vector2i(-1, 0):
			side = Side.LEFT
	if tile.is_connectable(neighbor_tile, side):
		return true
	return false


static func is_connectable_pos(tile_pos: Vector2i, neighbor_pos: Vector2i, dungeon: TileMapLayer) -> bool:
	var tile := create_from_id(dungeon.get_cell_source_id(tile_pos))
	match dungeon.get_cell_alternative_tile(tile_pos):
		TileRotation.ROTATE_90:
			tile.rotate_90()
		TileRotation.ROTATE_180:
			for i in 2:
				tile.rotate_90()
		TileRotation.ROTATE_270:
			for i in 3:
				tile.rotate_90()

	if is_connectable_tile_pos(tile, tile_pos, neighbor_pos, dungeon):
		return true
	return false
