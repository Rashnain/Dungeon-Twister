class_name Game extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

enum State { NEXT_PLAYER, DICE, MOVEMENT, CHOOSING_PLAYER, PLACING_TILE, CHOOSING_CARD, CHOOSING_TILE }

signal button_pressed

@onready var dungeon_back : TileMapLayer = $DungeonGridBack
@onready var dungeon_front : TileMapLayer = $DungeonGridFront
@onready var color_overlay : ColorRect = %ColorOverlay
@onready var texture_overlay_back : TextureRect = %TextureOverlayBack
@onready var texture_overlay_front : TextureRect = %TextureOverlayFront
@onready var camera : Camera2D = $Camera2D
@onready var stats : Label = %Stats
@onready var instructions : Label = %Instructions
static var d4_button : Button
static var d6_button : Button
static var card_button : Button
static var end_turn_button : Button
static var stop_placing_button : Button
static var back_button : Button
@onready var tile_stack_label : Label = %TileStack/Label
@onready var card_stack_label : Label = %CardStack/Label

var button_value
var player_playing := -1
var max_movement: int
var state := State.NEXT_PLAYER
var custom_cell_data := {}


func _ready() -> void:
	d4_button = %Die4Button
	d6_button = %Die6Button
	card_button = %CardButton
	end_turn_button = %EndTurnButton
	stop_placing_button = %StopPlacingButton
	back_button = %BackButton
	instructions.text = ""
	GD.init_game()
	tile_stack_label.text = "%s tiles" % len(GD.tile_stack)
	card_stack_label.text = "%s cards" % len(GD.card_stack)
	for pawn in GD.players_pawns:
		pawn.position = dungeon_back.map_to_local(Vector2i(6, 3))
		add_child(pawn)
	update_stats()


func _process(_delta: float) -> void:
	if state in [State.DICE, State.CHOOSING_CARD, State.CHOOSING_TILE]: return

	if state == State.NEXT_PLAYER:
		player_playing = (player_playing + 1) % GD.nr_players
		if instructions.text != "":
			instructions.text += "\n\n"
		if GD.players_skip_next_turn[player_playing]:
			instructions.text += "Player %d turn is skiped." % [player_playing+1]
			GD.players_skip_next_turn[player_playing] = false
			update_stats()
		else:
			instructions.text += "It is Player %d turn :\n" % [player_playing+1]
			state = State.DICE

	# Dice rolling
	if state == State.DICE:
			# Tiles / cards
			d6_button.visible = true
			await button_pressed
			d6_button.visible = false
			var die_value := randi_range(1, 6)
			match die_value:
				1:
					for j in 1:
						GD.draw_card(player_playing)
					instructions.text += " - They got 1 card"
				2:
					for j in 2:
						GD.draw_card(player_playing)
					instructions.text += " - They got 2 cards"
				3:
					for j in 2:
						GD.draw_tile(player_playing)
					instructions.text += " - They got 2 tiles"
				4:
					for j in 3:
						GD.draw_tile(player_playing)
					instructions.text += " - They got 3 tiles"
				_:
					for j in 1:
						GD.draw_tile(player_playing)
					instructions.text += " - They got 1 tile"
			update_stats()
			if len(GD.tile_stack) > 0:
				tile_stack_label.text = "%s tiles" % len(GD.tile_stack)
			else:
				tile_stack_label.text = "1 tile"
			if len(GD.card_stack) > 0:
				card_stack_label.text = "%s cards" % len(GD.card_stack)
			else:
				card_stack_label.text = "1 card"
			# Movement
			d4_button.visible = true
			if len(GD.players_cards[player_playing]) > 0:
				card_button.visible = true
			await button_pressed
			d4_button.visible = false
			card_button.visible = false
			if str(button_value) == "d4":
				max_movement = randi_range(1, 4)
				instructions.text += " and %d move(s)" % [max_movement]
				if len(GD.players_tiles[player_playing]) > 0:
					state = State.CHOOSING_TILE
				else:
					state = State.MOVEMENT
			elif str(button_value) == "card":
				state = State.CHOOSING_CARD

	# Movement
	if state == State.MOVEMENT:
		color_overlay.visible = true
		GD.players_pawns[player_playing].modulate = Color("ff0000")
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var pawn_tile := dungeon_back.local_to_map(GD.players_pawns[player_playing].position)
		var pos_diff: Vector2i = pawn_tile - tile_mouse
		if pos_diff.length() == 1:
			if Tile.is_connectable_pos(pawn_tile, tile_mouse, dungeon_back):
				color_overlay.color = Color("00ff007f")
				if Input.is_action_just_pressed("left_click") and not end_turn_button.is_hovered():
					var cell_alt := dungeon_front.get_cell_alternative_tile(tile_mouse)
					if custom_cell_data.has(tile_mouse):
						var real_id: int = custom_cell_data[tile_mouse]
						if real_id == 0:
							dungeon_front.set_cell(tile_mouse)
						else:
							if real_id == 5:
								generate_treasure()
							dungeon_front.set_cell(tile_mouse, real_id, Vector2i(0, 0), cell_alt)
						custom_cell_data.erase(tile_mouse)
					var pawn = GD.players_pawns[player_playing]
					pawn.position = dungeon_back.map_to_local(tile_mouse)
					max_movement -= 1
					if not max_movement:
						end_turn_button.visible = false
						color_overlay.visible = false
						GD.players_pawns[player_playing].modulate = Color("ffffff")
						state = State.NEXT_PLAYER
					else:
						end_turn_button.visible = true
					tile_effect(dungeon_front.get_cell_source_id(tile_mouse))
		else:
			color_overlay.color = Color("ff00007f")
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	# Choosing a player
	if state == State.CHOOSING_PLAYER:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		for pawn in GD.players_pawns:
			if pawn.pos == tile_mouse:
				color_overlay.color = Color("00ff007f")
			else:
				color_overlay.color = Color("ffffff7f")
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	#  Placing a tile
	if state == State.PLACING_TILE:
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var tile_id = GD.players_tiles[player_playing][int(button_value)]
		if Input.is_action_just_pressed("rotate"):
			texture_overlay_back.rotation_degrees += 90
		if dungeon_back.get_cell_source_id(tile_mouse) == -1 and \
				Tile.is_connectable_with_surrounding(tile_id % 5, tile_mouse, \
					int(texture_overlay_back.rotation_degrees / 90), dungeon_back):
			color_overlay.color = Color("00ff007f")
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
				dungeon_front.set_cell(tile_mouse, 0, Vector2i(0, 0))
				custom_cell_data[tile_mouse] = int(tile_id / 5)
				GD.players_tiles[player_playing].remove_at(int(button_value))
				update_stats()
				texture_overlay_back.visible = false
				texture_overlay_front.visible = false
				if GD.players_tiles[player_playing].is_empty():
					state = State.MOVEMENT
				else:
					stop_placing_button.visible = true
					texture_overlay_back.visible = false
					texture_overlay_front.visible = false
					color_overlay.visible = false
					state = State.CHOOSING_TILE
		else:
			color_overlay.color = Color("ff00007f")
		texture_overlay_back.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		texture_overlay_front.position = texture_overlay_back.position
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	#  Choosing a card
	if state == State.CHOOSING_CARD:
		Card.create_buttons(player_playing, camera, self)
		await button_pressed
		var card_id = GD.players_cards[player_playing][int(button_value)]
		GD.players_cards[player_playing].remove_at(int(button_value))
		Card.remove_buttons()
		update_stats()
		state = State.NEXT_PLAYER

	#  Choosing a tile
	if state == State.CHOOSING_TILE:
		Tile.create_buttons(player_playing, camera, self)
		stop_placing_button.visible = true
		await button_pressed
		Tile.remove_buttons()
		stop_placing_button.visible = false
		if button_value == "stop_placing":
			texture_overlay_back.visible = false
			texture_overlay_front.visible = false
			color_overlay.visible = false
			state = State.MOVEMENT
		else:
			var tile_id = GD.players_tiles[player_playing][int(button_value)]
			texture_overlay_back.texture = load("res://assets/tiles/%s.png" % [Tile.get_background_from_id(tile_id)])
			texture_overlay_front.texture = load("res://assets/tiles/%s.png" % [Tile.get_foreground_from_id(tile_id % 5)])
			texture_overlay_back.rotation_degrees = 0
			texture_overlay_back.visible = true
			texture_overlay_front.visible = true
			color_overlay.visible = true
			state = State.PLACING_TILE


func update_stats() -> void:
	var players_str = ""
	for i in GD.nr_players:
		players_str += "Player %d : %d coins" % [i+1, GD.players_money[i]]
		players_str += " / %d tile(s) / %d card(s)" % [len(GD.players_tiles[i]), len(GD.players_cards[i])]
		players_str += " [Skip next turn] " if GD.players_skip_next_turn[i] else ""
		players_str += " [Treasure boost] " if GD.players_has_treasure_boost[i] else ""
		players_str += " [Cancel next trap] " if GD.players_can_cancel_traps[i] else ""
		players_str += "\n"
	stats.text = players_str


func generate_treasure():
	var coins: int
	var cards: int
	match randi_range(1, 6):
		1:
			coins = 1
			cards = 1
		2:
			coins = 3
			cards = 0
		3:
			coins = 0
			cards = 2
		4:
			coins = 2
			cards = 1
		5:
			coins = 5
			cards = 0
		6:
			coins = 5
			cards = 2
	GD.players_money[player_playing] += coins
	for i in cards:
		GD.draw_card(player_playing)
	instructions.text += "\n - Treasure : %d coin(s) %d card(s)" % [coins, cards]
	update_stats()


func tile_effect(id: int) -> void:
	if id == 0 or id == 5: return
	match id:
		1:
			GD.players_tiles[player_playing].pop_at(randi_range(0, len(GD.players_tiles[player_playing])-1))
			instructions.text += "\n - One of their tiles were taken by a demon !"
		2:
			GD.players_cards[player_playing].pop_at(randi_range(0, len(GD.players_cards[player_playing])-1))
			instructions.text += "\n - They got trapped in spikes and lost a card !"
		3:
			GD.players_skip_next_turn[player_playing] = true
			instructions.text += "\n - They got lost in a infinte tunnel !"
		4:
			if GD.players_money[player_playing] > 1:
				GD.players_money[player_playing] -= 2
			instructions.text += "\n - A goblin robbed them 2 coins !"
	state = State.NEXT_PLAYER
	end_turn_button.visible = false
	color_overlay.visible = false
	GD.players_pawns[player_playing].modulate = Color("ffffff")
	update_stats()


static func is_mouse_over_a_button() -> bool:
	return d6_button.is_hovered() or d4_button.is_hovered() or \
		card_button.is_hovered() or end_turn_button.is_hovered() or \
		stop_placing_button.is_hovered() or back_button.is_hovered()


func _on_button_pressed(value: String) -> void:
	if value == "end_turn":
		end_turn_button.visible = false
		color_overlay.visible = false
		GD.players_pawns[player_playing].modulate = Color("ffffff")
		state = State.NEXT_PLAYER
	else:
		button_value = value
		button_pressed.emit()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
