class_name Game extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

enum State { NEXT_PLAYER, DICE, MOVEMENT, CHOOSING_PLAYER, PLACING_TILE, CHOOSING_CARD, CHOOSING_TILE }

signal button_pressed

@onready var dungeon_back: TileMapLayer = $DungeonGridBack
@onready var dungeon_front: TileMapLayer = $DungeonGridFront
@onready var color_overlay: ColorRect = %ColorOverlay
@onready var texture_overlay_back: TextureRect = %TextureOverlayBack
@onready var texture_overlay_front: TextureRect = %TextureOverlayFront
@onready var camera: Camera2D = $Camera2D
@onready var stats: Label = %Stats
@onready var instructions: RichTextLabel = %Instructions
@onready var d4_button: Button = %MoveButton
@onready var d6_button: Button = %ActionButton
@onready var card_button: Button = %CardButton
@onready var end_turn_button: Button = %EndTurnButton
@onready var stop_placing_button: Button = %StopPlacingButton
@onready var tile_stack_label: Label = %TileStack/Label
@onready var card_stack_label: Label = %CardStack/Label

var button_value
var player_playing := -1
var max_movement: int
var card_id: int
var state := State.NEXT_PLAYER
var turn := 0
var custom_cell_data := {}


func _ready() -> void:
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
		GD.players_pawns[player_playing].modulate = Color("ffffff")
		player_playing = (player_playing + 1) % GD.nr_players
		if instructions.text != "":
			instructions.text += "\n\n"
		if player_playing == 0:
			turn += 1
			instructions.text += "----- Turn %d -----\n\n" % turn
		if GD.players_skip_next_turn[player_playing]:
			instructions.text += "Player %d turn is skiped." % [player_playing+1]
			GD.players_skip_next_turn[player_playing] = false
			update_stats()
		else:
			instructions.text += "It is Player %d turn :" % [player_playing+1]
			GD.players_pawns[player_playing].modulate = Color("ff0000")
			state = State.DICE

	# Dice rolling
	if state == State.DICE:
			# Tiles / cards
			d6_button.visible = true
			await button_pressed
			d6_button.visible = false
			var die_value := randi_range(1, 6)
			var type: GD.Stack
			var amount: int
			match die_value:
				1:
					type = GD.Stack.CARD
					amount = 2
				2:
					type = GD.Stack.CARD
					amount = 1
				3:
					type = GD.Stack.TILE
					amount = 3
				4:
					type = GD.Stack.TILE
					amount = 2
				_:
					type = GD.Stack.TILE
					amount = 1
			if type == GD.Stack.TILE:
				instructions.text += "\n - They rolled a %d and got %d tile(s)" % [die_value, GD.draw(player_playing, type, amount)]
			else:
				instructions.text += "\n - They rolled a %d and got %d card(s)" % [die_value, GD.draw(player_playing, type, amount)]
			update_stats()
			if len(GD.tile_stack) > 1:
				tile_stack_label.text = "%d tiles" % len(GD.tile_stack)
			else:
				tile_stack_label.text = "%d tile" % len(GD.card_stack)
			if len(GD.card_stack) > 1:
				card_stack_label.text = "%d cards" % len(GD.card_stack)
			else:
				card_stack_label.text = "%d card" % len(GD.card_stack)
			# Movement
			d4_button.visible = true
			if len(GD.players_cards[player_playing]) > 0:
				card_button.visible = true
			await button_pressed
			d4_button.visible = false
			card_button.visible = false
			if str(button_value) == "d4":
				max_movement = randi_range(1, 4)
				instructions.text += "\n - They rolled a %d and got %d move(s)" % [max_movement, max_movement]
				if len(GD.players_tiles[player_playing]) > 0:
					state = State.CHOOSING_TILE
				else:
					state = State.MOVEMENT
			elif str(button_value) == "card":
				state = State.CHOOSING_CARD

	# Movement
	if state == State.MOVEMENT:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var pawn_tile := dungeon_back.local_to_map(GD.players_pawns[player_playing].position)
		var pos_diff: Vector2i = pawn_tile - tile_mouse
		if pos_diff.length() == 1:
			if Tile.is_connectable_pos(pawn_tile, tile_mouse, dungeon_back):
				color_overlay.color = Color("00ff007f")
				if Input.is_action_just_pressed("left_click") and not end_turn_button.is_hovered():
					var pawn = GD.players_pawns[player_playing]
					pawn.position = dungeon_back.map_to_local(tile_mouse)
					max_movement -= 1
					if not max_movement:
						end_turn_button.visible = false
						color_overlay.visible = false
						state = State.NEXT_PLAYER
					else:
						end_turn_button.visible = true
					reveal_tile(player_playing)
		else:
			color_overlay.color = Color("ff00007f")
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	# Choosing a player
	if state == State.CHOOSING_PLAYER:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		for i in len(GD.players_pawns):
			var pawn := GD.players_pawns[i]
			if i != player_playing and pawn.position == dungeon_back.map_to_local(tile_mouse):
				color_overlay.color = Color("00ff007f")
				if Input.is_action_just_pressed("left_click"):
					match card_id:
						0:
							var pos := pawn.position
							pawn.position = GD.players_pawns[player_playing].position
							GD.players_pawns[player_playing].position = pos
							instructions.text += "\n - They exchange position with Player %d" % [i+1]
							reveal_tile(player_playing)
							reveal_tile(i)
						1:
							GD.players_skip_next_turn[i] = true
							instructions.text += "\n - They skipped Player %d's next turn" % [i+1]
						2:
							var money: int = min(GD.players_money[i], 3)
							GD.players_money[i] -= money
							GD.players_money[player_playing] += money
							instructions.text += "\n - They have stolen %d coin(s) from Player %d" % [money, i+1]
						3:
							var valid_pos: Array[Vector2i] = []
							for pos in dungeon_back.get_surrounding_cells(tile_mouse):
								if Tile.is_connectable_pos(pos, tile_mouse, dungeon_back):
									valid_pos.append(pos)
							pawn.position = dungeon_back.map_to_local(valid_pos[randi_range(0, len(valid_pos)-1)])
							instructions.text += "\n - They pushed Player %d !" % [i+1]
							reveal_tile(i)
						4:
							if GD.players_cards[i].is_empty():
								instructions.text += "\n - They tried to steal Player %d\n    but they don't have any card..." % i
							else:
								var index := randi_range(1, len(GD.players_cards[i]))
								GD.players_cards[player_playing].append(GD.players_cards[i].pop_at(index-1))
								instructions.text += "\n - They stole a card from Player %d" % [i+1]
					color_overlay.visible = false
					update_stats()
					state = State.NEXT_PLAYER
				break
			else:
				color_overlay.color = Color("ff00007f")

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
		card_id = GD.players_cards[player_playing][int(button_value)]
		match card_id:
			0, 1, 2, 3, 4:
				state = State.CHOOSING_PLAYER
			5:
				GD.players_can_cancel_traps[player_playing] = true
				instructions.text += "\n - They activate a trap canceller"
				state = State.NEXT_PLAYER
			6:
				GD.players_has_treasure_boost[player_playing] = true
				instructions.text += "\n - They activate a treasure booster"
				state = State.NEXT_PLAYER
			7:
				instructions.text += "\n - [TODO] insight card"
				state = State.NEXT_PLAYER
			8:
				instructions.text += "\n - [TODO] goblin card"
				state = State.NEXT_PLAYER
			9:
				instructions.text += "\n - [TODO] switch tile card"
				state = State.NEXT_PLAYER
		GD.players_cards[player_playing].remove_at(int(button_value))
		Card.remove_buttons()
		update_stats()

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


func generate_treasure() -> void:
	var coins: int
	var cards: int
	var multiplier := 1
	if GD.players_has_treasure_boost[player_playing]:
		instructions.text += "\n - They use their treasure boost !"
		multiplier = 2
		GD.players_has_treasure_boost[player_playing] = false
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
	GD.players_money[player_playing] += coins * multiplier
	GD.draw(player_playing, GD.Stack.CARD, cards * multiplier)
	instructions.text += "\n - Treasure : %d coin(s) %d card(s)" % [coins*multiplier, cards*multiplier]
	update_stats()


func reveal_tile(player_id: int) -> void:
	var pawn_pos := dungeon_back.local_to_map(GD.players_pawns[player_id].position)
	var cell_alt := dungeon_front.get_cell_alternative_tile(pawn_pos)
	if custom_cell_data.has(pawn_pos):
		var real_id: int = custom_cell_data[pawn_pos]
		if real_id == 0:
			dungeon_front.set_cell(pawn_pos)
		else:
			if real_id == 5:
				generate_treasure()
			dungeon_front.set_cell(pawn_pos, real_id, Vector2i(0, 0), cell_alt)
		custom_cell_data.erase(pawn_pos)
	var id := dungeon_front.get_cell_source_id(pawn_pos)
	if id < 1 or id == 5: return
	if GD.players_can_cancel_traps[player_id]:
		instructions.text += "\n - Their trap canceller prevent the trap !"
		GD.players_can_cancel_traps[player_id] = false
		update_stats()
		return
	match id:
		1:
			if len(GD.players_tiles[player_id]):
				GD.players_tiles[player_id].pop_at(randi_range(0, len(GD.players_tiles[player_id])-1))
				if player_id == player_playing:
					instructions.text += "\n - One of their tiles were taken by a demon !"
				else:
					instructions.text += "\n - One of Player %d tiles were taken by a demon !" % [player_id+1]
			else:
				if player_id == player_playing:
					instructions.text += "\n - They accountered a demon but\n    nothing happened"
				else:
					instructions.text += "\n - Player %d accountered a demon but\n    nothing happened" % [player_id+1]
		2:
			if len(GD.players_cards[player_id]):
				GD.players_cards[player_id].pop_at(randi_range(0, len(GD.players_cards[player_id])-1))
				if player_id == player_playing:
					instructions.text += "\n - They got trapped in spikes and lost a card !"
				else:
					instructions.text += "\n - Player %d got trapped in spikes and lost a card !" % [player_id+1]
			else:
				if player_id == player_playing:
					instructions.text += "\n - They got trapped in spikes but\n    nothing happened"
				else:
					instructions.text += "\n - Player %d got trapped in spikes but\n    nothing happened" % [player_id+1]
		3:
			GD.players_skip_next_turn[player_id] = true
			if player_id == player_playing:
				instructions.text += "\n - They got lost in a infinte tunnel !"
			else:
					instructions.text += "\n - Player %d got lost in a infinte tunnel !" % [player_id+1]
		4:
			var money = min(GD.players_money[player_id], 2)
			if GD.players_money[player_id]:
				GD.players_money[player_id] -= money
			if player_id == player_playing:
				instructions.text += "\n - A goblin robbed them %d coins !" % money
			else:
					instructions.text += "\n - A goblin robbed %d coins of Player %d !" % [money, player_id+1]
	if player_id == player_playing:
		state = State.NEXT_PLAYER
		end_turn_button.visible = false
		color_overlay.visible = false
		GD.players_pawns[player_id].modulate = Color("ffffff")
	update_stats()


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
