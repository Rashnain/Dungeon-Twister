extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}


@onready var dungeon : TileMapLayer = $DungeonGrid
@onready var color_overlay : ColorRect = %ColorOverlay
@onready var texture_overlay : TextureRect = %TextureOverlay
@onready var stats : Label = %Stats
@onready var instructions : Label = %Instructions
@onready var d4_button : Button = %Die4Button
@onready var d6_button : Button = %Die6Button

var player_playing := -1
var mode := 0


func _ready() -> void:
	Game.init_game()
	for pawn in Game.players_pawns:
		pawn.position = dungeon.map_to_local(pawn.pos)
		add_child(pawn)
	update_stats()


func _process(_delta: float) -> void:
	if mode == 1: return

	if mode == 0:
		player_playing = (player_playing + 1) % Game.nr_players
		mode = 1

	# Dice rolling
	if mode == 1:
		instructions.text = "It is Player %d's turn\n" % [player_playing+1]
		if not Game.players_skip_next_turn[player_playing]:
			# Tiles / cards
			d6_button.visible = true
			await d6_button.button_up
			d6_button.visible = false
			var die_value := d6()
			match die_value:
				1:
					for j in 1:
						Game.draw_card(player_playing)
					instructions.text += "They got 1 card"
				2:
					for j in 2:
						Game.draw_card(player_playing)
					instructions.text += "They got 2 cards"
				3:
					for j in 2:
						Game.draw_tile(player_playing)
					instructions.text += "They got 2 tiles"
				4:
					for j in 3:
						Game.draw_tile(player_playing)
					instructions.text += "They got 3 tiles"
				_:
					for j in 1:
						Game.draw_tile(player_playing)
					instructions.text += "They got 1 tile"
			# Movement
			d4_button.visible = true
			await d4_button.button_up
			d4_button.visible = false
			die_value = d4()
			instructions.text += " and %d move(s)" % [die_value]
			instructions.text += "\nCards : %s" % str(Game.players_cards[player_playing])
			instructions.text += "\nTiles : %s" % str(Game.players_tiles[player_playing])
			update_stats()
			if len(Game.players_tiles[player_playing]) > 0:
				mode = 4
			else:
				mode = 2

	# Movement
	if mode == 2:
		color_overlay.visible = true
		var tile_mouse = dungeon.local_to_map(dungeon.get_local_mouse_position())
		var data = dungeon.get_cell_tile_data(tile_mouse)
		if data:
			color_overlay.color = Color("00ff007f")
		else:
			color_overlay.color = Color("ffffff7f")
		color_overlay.position = dungeon.map_to_local(tile_mouse) - Vector2(50, 50)

	# Choosing a player
	if mode == 3:
		color_overlay.visible = true
		var tile_mouse = dungeon.local_to_map(dungeon.get_local_mouse_position())
		for pawn in Game.players_pawns:
			if pawn.pos == tile_mouse:
				color_overlay.color = Color("00ff007f")
			else:
				color_overlay.color = Color("ffffff7f")
		color_overlay.position = dungeon.map_to_local(tile_mouse) - Vector2(50, 50)

	#  Placing a tile
	if mode == 4:
		texture_overlay.visible = true
		var tile_mouse = dungeon.local_to_map(dungeon.get_local_mouse_position())
		texture_overlay.texture = Tile.get_texture_from_id(Game.players_tiles[player_playing][0])
		texture_overlay.position = dungeon.map_to_local(tile_mouse) - Vector2(50, 50)


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
