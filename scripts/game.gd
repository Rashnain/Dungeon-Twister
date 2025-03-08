class_name Game extends Node2D


enum TileRotation {
	ROTATE_0 = 0,
	ROTATE_90 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
	ROTATE_180 = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
	ROTATE_270 = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
}

enum State { NEXT_PLAYER, DICE, MOVEMENT, CHOOSING_PLAYER, PLACING_TILE, CHOOSING_CARD,
			CHOOSING_TILE, GOBLIN_CARD, INSIGHT_CARD }

signal button_pressed

@onready var dungeon_back: TileMapLayer = $DungeonGridBack
@onready var dungeon_front: TileMapLayer = $DungeonGridFront
@onready var color_overlay: ColorRect = %ColorOverlay
@onready var texture_overlay_back: TextureRect = %TextureOverlayBack
@onready var texture_overlay_front: TextureRect = %TextureOverlayFront
@onready var camera: Camera2D = $Camera2D
@onready var history: RichTextLabel = %History
@onready var d4_button: Button = %MoveButton
@onready var d6_button: Button = %ActionButton
@onready var card_button: Button = %CardButton
@onready var end_turn_button: Button = %EndTurnButton
@onready var stop_placing_button: Button = %StopPlacingButton
@onready var cancel_placing_button: Button = %CancelPlacingButton
@onready var tile_stack_label: Label = %TileStack/Label
@onready var card_stack_label: Label = %CardStack/Label
@onready var overlay: Control = %Overlay

var button_value
var player_playing := -1
var max_movement: int
var card_id: int
var state := State.NEXT_PLAYER
var turn := 0
var custom_cell_data := {}


func _ready() -> void:
	history.text = ""
	GM.init_game()
	tile_stack_label.text = "%s tiles" % len(GM.tile_stack)
	card_stack_label.text = "%s cards" % len(GM.card_stack)
	for player in GM.players:
		player.pawn.position = dungeon_back.map_to_local(Vector2i(6, 3))
		add_child(player.pawn)
		camera.add_child(player)
	GM.update_stats()


func _process(_delta: float) -> void:
	if state in [State.DICE, State.CHOOSING_CARD]: return

	if state == State.NEXT_PLAYER:
		end_turn_button.visible = false
		GM.players[player_playing].pawn.modulate = Color("ffffff")
		GM.players[player_playing].background.color = Color("646464e0")
		player_playing = (player_playing + 1) % GM.nr_players
		if history.text != "":
			history.text += "\n\n"
		if player_playing == 0:
			if len(GM.tile_stack) == 0:
				overlay.message.text = "End of game\n\n"
				var already_listed := []
				for number in len(GM.players):
					var best_player := -1
					var best_score := -1
					for j in len(GM.players):
						if j not in already_listed and GM.players[j].money > best_score:
							best_player = j
							best_score = GM.players[j].money
					already_listed.append(best_player)
					overlay.message.text += "%d - Player %d with %d coin(s)\n " % [number+1, best_player+1, best_score]
				overlay.back_button.visible = true
				overlay.visible = true
				get_tree().paused = true
				return
			turn += 1
			history.text += "----- Turn %d -----\n\n" % turn
		if GM.players[player_playing].skip_next_turn:
			history.text += "Player %d turn is skiped." % [player_playing+1]
			GM.players[player_playing].skip_next_turn = false
		else:
			history.text += "It is Player %d turn :" % [player_playing+1]
			GM.players[player_playing].pawn.modulate = Color("ff0000")
			#GM.players[player_playing].background.color = Color("9a9a9ae0")
			GM.players[player_playing].background.color = Color("7f7f7fe0")
			state = State.DICE

	if state == State.DICE:
			# Tiles / cards
			d6_button.visible = true
			await button_pressed
			d6_button.visible = false
			var die_value := randi_range(1, 6)
			var type: GM.Stack
			var amount: int
			match die_value:
				1:
					type = GM.Stack.CARD
					amount = 2
				2:
					type = GM.Stack.CARD
					amount = 1
				3:
					type = GM.Stack.TILE
					amount = 3
				4:
					type = GM.Stack.TILE
					amount = 2
				_:
					type = GM.Stack.TILE
					amount = 1
			if type == GM.Stack.TILE:
				history.text += "\n - They rolled a %d and got %d tile(s)" % [die_value, GM.draw(player_playing, type, amount)]
			else:
				history.text += "\n - They rolled a %d and got %d card(s)" % [die_value, GM.draw(player_playing, type, amount)]
			GM.update_stats()
			if len(GM.tile_stack) > 1:
				tile_stack_label.text = "%d tiles" % len(GM.tile_stack)
			else:
				tile_stack_label.text = "%d tile" % len(GM.card_stack)
			if len(GM.card_stack) > 1:
				card_stack_label.text = "%d cards" % len(GM.card_stack)
			else:
				card_stack_label.text = "%d card" % len(GM.card_stack)
			# Movement
			d4_button.visible = true
			if len(GM.players[player_playing].cards) > 0:
				card_button.visible = true
			await button_pressed
			d4_button.visible = false
			card_button.visible = false
			if str(button_value) == "d4":
				max_movement = randi_range(1, 4)
				history.text += "\n - They rolled a %d and got %d move(s)" % [max_movement, max_movement]
				if len(GM.players[player_playing].tiles) > 0:
					state = State.CHOOSING_TILE
				else:
					state = State.MOVEMENT
			elif str(button_value) == "card":
				state = State.CHOOSING_CARD

	if state == State.MOVEMENT:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var pawn_tile := dungeon_back.local_to_map(GM.players[player_playing].pawn.position)
		var pos_diff: Vector2i = pawn_tile - tile_mouse
		if pos_diff.length() == 1:
			if Tile.is_connectable_pos(pawn_tile, tile_mouse, dungeon_back):
				color_overlay.color = Color("00ff007f")
				if Input.is_action_just_pressed("left_click") and not end_turn_button.is_hovered():
					var pawn = GM.players[player_playing].pawn
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

	if state == State.CHOOSING_PLAYER:
		color_overlay.visible = true
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		for i in len(GM.players):
			var pawn := GM.players[i].pawn
			if i != player_playing and pawn.position == dungeon_back.map_to_local(tile_mouse):
				color_overlay.color = Color("00ff007f")
				if Input.is_action_just_pressed("left_click"):
					match card_id:
						0:
							var pos := pawn.position
							pawn.position = GM.players[player_playing].pawn.position
							GM.players[player_playing].pawn.position = pos
							history.text += "\n - They exchange position with Player %d" % [i+1]
							reveal_tile(player_playing)
							reveal_tile(i)
						1:
							GM.players[i].skip_next_turn = true
							history.text += "\n - They skipped Player %d's next turn" % [i+1]
						2:
							var money: int = min(GM.players[i].money, 3)
							GM.players[i].money -= money
							GM.players[player_playing].money += money
							history.text += "\n - They have stolen %d coin(s) from Player %d" % [money, i+1]
						3:
							var valid_pos: Array[Vector2i] = []
							for pos in dungeon_back.get_surrounding_cells(tile_mouse):
								if Tile.is_connectable_pos(pos, tile_mouse, dungeon_back):
									valid_pos.append(pos)
							pawn.position = dungeon_back.map_to_local(valid_pos[randi_range(0, len(valid_pos)-1)])
							history.text += "\n - They pushed Player %d !" % [i+1]
							reveal_tile(i)
						4:
							if GM.players[i].cards.is_empty():
								history.text += "\n - They tried to steal Player %d but they don't have any card..." % [i+1]
							else:
								var index := randi_range(1, len(GM.players[i].cards))
								GM.players[player_playing].cards.append(GM.players[i].cards.pop_at(index-1))
								history.text += "\n - They stole a card from Player %d" % [i+1]
								GM.update_stats()
					color_overlay.visible = false
					state = State.NEXT_PLAYER
				break
			else:
				color_overlay.color = Color("ff00007f")

	if state == State.PLACING_TILE:
		var tile_mouse = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		var tile_id = GM.players[player_playing].tiles[int(button_value)]
		if Input.is_action_just_pressed("rotate"):
			texture_overlay_back.rotation_degrees += 90
		if ((card_id != 9 and dungeon_back.get_cell_source_id(tile_mouse) == -1) or \
				(card_id == 9 and dungeon_back.get_cell_source_id(tile_mouse) != -1)) and \
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
				custom_cell_data[tile_mouse] = tile_id / 5
				GM.players[player_playing].tiles.remove_at(int(button_value))
				GM.update_stats()
				if card_id == 9:
					if GM.players[player_playing].pawn.position == dungeon_front.map_to_local(tile_mouse):
						reveal_tile(player_playing)
					for i in len(GM.players):
						if i == player_playing: continue
						if GM.players[i].pawn.position == dungeon_front.map_to_local(tile_mouse):
							reveal_tile(i)
				texture_overlay_back.visible = false
				texture_overlay_front.visible = false
				cancel_placing_button.visible = false
				if GM.players[player_playing].tiles.is_empty():
					if card_id == 9:
						card_id = -1
						color_overlay.visible = false
						state = State.NEXT_PLAYER
					else:
						state = State.MOVEMENT
				else:
					stop_placing_button.visible = true
					texture_overlay_back.visible = false
					texture_overlay_front.visible = false
					color_overlay.visible = false
					if card_id == 9:
						card_id = -1
						stop_placing_button.visible = false
						state = State.NEXT_PLAYER
					else:
						state = State.CHOOSING_TILE
		else:
			color_overlay.color = Color("ff00007f")
		texture_overlay_back.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)
		texture_overlay_front.position = texture_overlay_back.position
		color_overlay.position = dungeon_back.map_to_local(tile_mouse) - Vector2(50, 50)

	if state == State.CHOOSING_CARD:
		Card.create_buttons(player_playing, camera, self)
		await button_pressed
		card_id = GM.players[player_playing].cards[int(button_value)]
		match card_id:
			0, 1, 2, 3, 4:
				state = State.CHOOSING_PLAYER
			5:
				GM.players[player_playing].can_cancel_traps = true
				history.text += "\n - They activate a trap canceller"
				state = State.NEXT_PLAYER
			6:
				GM.players[player_playing].has_treasure_boost = true
				history.text += "\n - They activate a treasure booster"
				state = State.NEXT_PLAYER
			7:
				texture_overlay_front.texture = null
				texture_overlay_front.visible = true
				color_overlay.visible = true
				end_turn_button.visible = true
				state = State.INSIGHT_CARD
			8:
				texture_overlay_front.texture = load("res://assets/tiles/goblin.png")
				texture_overlay_front.visible = true
				color_overlay.visible = true
				state = State.GOBLIN_CARD
			9:
				if len(GM.players[player_playing].tiles) > 0:
					state = State.CHOOSING_TILE
					history.text += "\n - They used a switch tile card"
				else:
					history.text += "\n - They used a switch tile card but they don't have any tile to switch with."
					state = State.NEXT_PLAYER
		GM.players[player_playing].cards.remove_at(int(button_value))
		Card.remove_buttons()
		GM.update_stats()

	if state == State.CHOOSING_TILE:
		Tile.create_buttons(player_playing, camera, self)
		stop_placing_button.visible = true
		state = State.DICE
		await button_pressed
		Tile.remove_buttons()
		stop_placing_button.visible = false
		if button_value == "stop_placing":
			texture_overlay_back.visible = false
			texture_overlay_front.visible = false
			color_overlay.visible = false
			if card_id == 9:
				card_id = -1
				history.text += " that they cancelled."
				state = State.NEXT_PLAYER
			else:
				state = State.MOVEMENT
		else:
			var tile_id = GM.players[player_playing].tiles[int(button_value)]
			texture_overlay_back.texture = load("res://assets/tiles/%s.png" % [Tile.get_background_from_id(tile_id)])
			texture_overlay_front.texture = load("res://assets/tiles/%s.png" % [Tile.get_foreground_from_id(tile_id % 5)])
			texture_overlay_back.rotation_degrees = 0
			texture_overlay_back.visible = true
			texture_overlay_front.visible = true
			color_overlay.visible = true
			cancel_placing_button.visible = true
			state = State.PLACING_TILE

	if state == State.GOBLIN_CARD:
		var mouse_tile = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		if dungeon_front.get_cell_source_id(mouse_tile) == -1:
			color_overlay.color = Color("00ff007f")
			if Input.is_action_just_pressed("left_click"):
				dungeon_front.set_cell(mouse_tile, 4, Vector2i(0, 0))
				history.text += "\n - They spawned a goblin in the dungeon !"
				if GM.players[player_playing].pawn.position == dungeon_front.map_to_local(mouse_tile):
					reveal_tile(player_playing)
				for i in len(GM.players):
					if i == player_playing: continue
					if GM.players[i].pawn.position == dungeon_front.map_to_local(mouse_tile):
						reveal_tile(i)
				texture_overlay_front.visible = false
				color_overlay.visible = false
				state = State.NEXT_PLAYER
		else:
			color_overlay.color = Color("ff00007f")
		texture_overlay_front.position = dungeon_back.map_to_local(mouse_tile) - Vector2(50, 50)
		color_overlay.position = dungeon_back.map_to_local(mouse_tile) - Vector2(50, 50)

	if state == State.INSIGHT_CARD:
		var mouse_tile = dungeon_back.local_to_map(dungeon_back.get_local_mouse_position())
		if custom_cell_data.has(mouse_tile):
			color_overlay.color = Color("00ff007f")
			if Input.is_action_just_pressed("left_click"):
				var front_tile_id: int = custom_cell_data[mouse_tile]
				if front_tile_id != 0:
					texture_overlay_front.texture = load("res://assets/tiles/%s.png" % Tile.get_foreground_from_id(front_tile_id*5))
				history.text += "\n - They used their insight card to see what others can't"
				dungeon_front.set_cell(mouse_tile)
				state = State.DICE
				await get_tree().create_timer(1.0).timeout
				dungeon_front.set_cell(mouse_tile, 0, Vector2i(0, 0))
				texture_overlay_front.visible = false
				color_overlay.visible = false
				state = State.NEXT_PLAYER
		else:
			color_overlay.color = Color("ff00007f")
		texture_overlay_front.position = dungeon_back.map_to_local(mouse_tile) - Vector2(50, 50)
		color_overlay.position = dungeon_back.map_to_local(mouse_tile) - Vector2(50, 50)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Input.is_action_just_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			overlay.message.text = "Game paused\n "
			overlay.continue_button.visible = true
			overlay.back_button.visible = true
			overlay.visible = true
			get_tree().paused = true


func generate_treasure() -> void:
	camera.pressed = false
	var tongue_twister := GM.pick_random_tongue_twister()
	overlay.message.text = "Repeat this :\n\n[b]%s[/b]\n " % tongue_twister
	overlay.continue_button.visible = true
	overlay.visible = true
	get_tree().paused = true
	var coins: int
	var cards: int
	var multiplier := 1
	if GM.players[player_playing].has_treasure_boost:
		history.text += "\n - They use their treasure boost !"
		multiplier = 2
		GM.players[player_playing].has_treasure_boost = false
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
	GM.players[player_playing].money += coins * multiplier
	GM.draw(player_playing, GM.Stack.CARD, cards * multiplier)
	history.text += "\n - Treasure : %d coin(s) %d card(s)" % [coins*multiplier, cards*multiplier]
	GM.update_stats()


func reveal_tile(player_index: int) -> void:
	var pawn_pos := dungeon_back.local_to_map(GM.players[player_index].pawn.position)
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
	if GM.players[player_index].can_cancel_traps:
		history.text += "\n - Their trap canceller prevent the trap !"
		GM.players[player_index].can_cancel_traps = false
		return
	match id:
		1:
			if len(GM.players[player_index].tiles):
				GM.players[player_index].tiles.pop_at(randi_range(0, len(GM.players[player_index].tiles)-1))
				if player_index == player_playing:
					history.text += "\n - One of their tiles were taken by a demon !"
				else:
					history.text += "\n - One of Player %d tiles were taken by a demon !" % [player_index+1]
			else:
				if player_index == player_playing:
					history.text += "\n - They accountered a demon but nothing happened"
				else:
					history.text += "\n - Player %d accountered a demon but nothing happened" % [player_index+1]
		2:
			if len(GM.players[player_index].cards):
				GM.players[player_index].cards.pop_at(randi_range(0, len(GM.players[player_index].cards)-1))
				if player_index == player_playing:
					history.text += "\n - They got trapped in spikes and lost a card !"
				else:
					history.text += "\n - Player %d got trapped in spikes and lost a card !" % [player_index+1]
			else:
				if player_index == player_playing:
					history.text += "\n - They got trapped in spikes but nothing happened"
				else:
					history.text += "\n - Player %d got trapped in spikes but nothing happened" % [player_index+1]
		3:
			GM.players[player_index].skip_next_turn = true
			if player_index == player_playing:
				history.text += "\n - They got lost in a infinte tunnel !"
			else:
					history.text += "\n - Player %d got lost in a infinte tunnel !" % [player_index+1]
		4:
			var money = min(GM.players[player_index].money, 2)
			if GM.players[player_index].money:
				GM.players[player_index].money -= money
			if player_index == player_playing:
				history.text += "\n - A goblin robbed them %d coins !" % money
			else:
				history.text += "\n - A goblin robbed %d coins from Player %d !" % [money, player_index+1]
	if player_index == player_playing:
		state = State.NEXT_PLAYER
		end_turn_button.visible = false
		color_overlay.visible = false
		GM.players[player_index].pawn.modulate = Color("ffffff")
		GM.players[player_playing].background.color = Color("646464e0")
	GM.update_stats()


func _on_button_pressed(value: String) -> void:
	if value == "end_turn":
		end_turn_button.visible = false
		color_overlay.visible = false
		GM.players[player_playing].pawn.modulate = Color("ffffff")
		GM.players[player_playing].background.color = Color("646464e0")
		state = State.NEXT_PLAYER
	elif value == "cancel_placing":
		cancel_placing_button.visible = false
		texture_overlay_back.visible = false
		texture_overlay_front.visible = false
		color_overlay.visible = false
		state = State.CHOOSING_TILE
	else:
		button_value = value
		button_pressed.emit()
