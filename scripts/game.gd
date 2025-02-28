extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

enum State {
	NEXT_PLAYER, DICE, MOVEMENT, CHOOSING_PLAYER, PLACING_TILE, CHOOSING_CARD, CHOOSING_TILE
}

signal button_pressed

@onready var dungeon_back : TileMapLayer = $DungeonGridBack
@onready var dungeon_front : TileMapLayer = $DungeonGridFront
@onready var color_overlay : ColorRect = %ColorOverlay
@onready var texture_overlay_back : TextureRect = %TextureOverlayBack
@onready var texture_overlay_front : TextureRect = %TextureOverlayFront
@onready var camera : Camera2D = $Camera2D
@onready var stats : Label = %Stats
@onready var instructions : Label = %Instructions
@onready var d4_button : Button = %Die4Button
@onready var d6_button : Button = %Die6Button
@onready var card_button : Button = %CardButton

var button_value
var player_playing := -1
var mode := State.NEXT_PLAYER


func _ready() -> void:
	Game.init_game()
	for pawn in Game.players_pawns:
		pawn.position = dungeon_back.map_to_local(Vector2i(6, 3))
		add_child(pawn)
	update_stats()


func _process(_delta: float) -> void:
	if mode == State.DICE or mode == State.CHOOSING_CARD or mode == State.CHOOSING_TILE: return

	if mode == State.NEXT_PLAYER:
		player_playing = (player_playing + 1) % Game.nr_players
		mode = State.DICE

	# Dice rolling
	if mode == State.DICE:
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
			if len(Game.players_cards[player_playing]) > 0:
				card_button.visible = true
			await button_pressed
			d4_button.visible = false
			card_button.visible = false
			if str(button_value) == "d4":
				die_value = randi_range(1, 4)
				instructions.text += " and %d move(s)" % [die_value]
				if len(Game.players_tiles[player_playing]) > 0:
					Tile.create_buttons(player_playing, camera, self)
					mode = State.CHOOSING_TILE
				else:
					mode = State.MOVEMENT
			elif str(button_value) == "card":
				Card.create_buttons(player_playing, camera, self)
				mode = State.CHOOSING_CARD

	# Movement
	if mode == State.MOVEMENT:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var data = dungeon_back.get_cell_tile_data(tile_mouse)
		if data:
			color_overlay.color = Color("00ff007f")
		else:
			color_overlay.color = Color("ffffff7f")
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		# TODO check that the path is valid
		# TODO reveal tile if unknown
		# TODO move more than one time
		# TODO tile effect
		if Input.is_action_just_pressed("left_click"):
			var pawn = Game.players_pawns[player_playing]
			pawn.position = dungeon_back.map_to_local(tile_mouse)
			color_overlay.visible = false
			mode = State.NEXT_PLAYER

	# Choosing a player
	if mode == State.CHOOSING_PLAYER:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		for pawn in Game.players_pawns:
			if pawn.pos == tile_mouse:
				color_overlay.color = Color("00ff007f")
			else:
				color_overlay.color = Color("ffffff7f")
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	#  Placing a tile
	if mode == State.PLACING_TILE:
		texture_overlay_back.visible = true
		texture_overlay_front.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var tile_id = Game.players_tiles[player_playing][int(button_value)]
		texture_overlay_back.texture = load("res://assets/tiles/%s.png" % [Tile.get_background_from_id(tile_id)])
		texture_overlay_front.texture = load("res://assets/tiles/%s.png" % [Tile.get_foreground_from_id(tile_id % 5)])
		texture_overlay_back.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		texture_overlay_front.position = texture_overlay_back.position
		if Input.is_action_just_pressed("rotate"):
			texture_overlay_back.rotation_degrees += 90
		if Input.is_action_just_pressed("left_click"):
			match int(texture_overlay_back.rotation_degrees) % 360:
				0:
					dungeon_back.set_cell(tile_mouse, tile_id % 5, Vector2i(0, 0), TileRotation.ROTATE_0)
				90:
					dungeon_back.set_cell(tile_mouse, tile_id % 5, Vector2i(0, 0), TileRotation.ROTATE_90)
				180:
					dungeon_back.set_cell(tile_mouse, tile_id % 5, Vector2i(0, 0), TileRotation.ROTATE_180)
				270:
					dungeon_back.set_cell(tile_mouse, tile_id % 5, Vector2i(0, 0), TileRotation.ROTATE_270)
			dungeon_front.set_cell(tile_mouse, 10, Vector2i(0, 0))
			dungeon_front.get_cell_tile_data(tile_mouse).set_custom_data("real_id", tile_id)
			Game.players_tiles[player_playing].remove_at(int(button_value))
			texture_overlay_back.visible = false
			texture_overlay_front.visible = false
			mode = State.MOVEMENT

	#  Choosing a card
	if mode == State.CHOOSING_CARD:
		await button_pressed
		var card_id = Game.players_cards[player_playing][int(button_value)]
		match card_id:
			_:
				print("TODO")
				# TODO card effects
		Game.players_cards[player_playing].remove_at(int(button_value))
		Card.remove_buttons()
		mode = State.NEXT_PLAYER

	#  Choosing a tile
	if mode == State.CHOOSING_TILE:
		await button_pressed
		Tile.remove_buttons()
		mode = State.PLACING_TILE


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
