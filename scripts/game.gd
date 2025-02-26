extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

signal button_pressed

@onready var dungeon : TileMapLayer = $DungeonGrid
@onready var color_overlay : ColorRect = %ColorOverlay
@onready var texture_overlay : TextureRect = %TextureOverlay
@onready var stats : Label = %Stats
@onready var instructions : Label = %Instructions
@onready var d4_button : Button = %Die4Button
@onready var d6_button : Button = %Die6Button
@onready var card_button : Button = %CardButton

var button_value: String
var player_playing := -1
var mode := 0 # TODO create an enum for the mode


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
			await button_pressed
			d6_button.visible = false
			var die_value := randi_range(1, 6)
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
			card_button.visible = true
			await button_pressed
			d4_button.visible = false
			card_button.visible = false
			if button_value == "d4":
				die_value = randi_range(1, 4)
				instructions.text += " and %d move(s)" % [die_value]
				mode = 2
			elif button_value == "card":
				mode = 5

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
		# TODO check that the path is valid
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pawn = Game.players_pawns[player_playing]
			pawn.position = dungeon.map_to_local(tile_mouse)
			color_overlay.visible = false
			mode = 0

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
		# TODO tile rotation with R

	#  Choosing a card
	if mode == 5:
		# TODO create buttons to choose the card
		await button_pressed

	#  Choosing a tile
	if mode == 6:
		# TODO create buttons to choose the tile
		await button_pressed


func update_stats() -> void:
	var players_str = ""
	for i in Game.nr_players:
		players_str += "Player %d : %d coins" % [i+1, Game.players_money[i]]
		players_str += " [Skip next turn] " if Game.players_skip_next_turn[i] else ""
		players_str += " [Treasure boost] " if Game.players_has_treasure_boost[i] else ""
		players_str += " [Cancel next trap] " if Game.players_can_cancel_traps[i] else ""
		players_str += "\n"
	stats.text = players_str


func _on_button_pressed(value: String) -> void:
	button_value = value
	button_pressed.emit()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
