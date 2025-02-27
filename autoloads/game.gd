extends Node


var nr_players: int
var players_money: Array[int]
var players_pawns: Array[Pawn]
var players_cards: Array[Array]
var players_tiles: Array[Array]
var players_can_cancel_traps: Array[bool]
var players_skip_next_turn: Array[bool]
var players_has_treasure_boost: Array[bool]

var tile_stack : Array[int]
var card_stack : Array[int]


func init_game() -> void:
	# Players stats
	players_money.clear()
	players_pawns.clear()
	players_cards.clear()
	players_tiles.clear()
	players_can_cancel_traps.clear()
	players_skip_next_turn.clear()
	players_has_treasure_boost.clear()
	for i in nr_players:
		players_money.append(0)
		var pawn := Pawn.new()
		pawn.texture = load("res://assets/pawns/%d.png" % i)
		pawn.z_index = 2
		pawn.pos = Vector2i(6, 3)
		players_pawns.append(pawn)
		players_cards.append([])
		players_tiles.append([])
		players_can_cancel_traps.append(false)
		players_skip_next_turn.append(false)
		players_has_treasure_boost.append(false)

	# Cards
	card_stack.clear()
	for i in 10:
		for j in 3:
			card_stack.append(i)
	card_stack.shuffle()

	# Tiles
	tile_stack.clear()
	# Empty tiles
	for i in 5:
		tile_stack.append(0) # Four ways
	for i in 10:
		tile_stack.append(1) # Corridor
	for i in 10:
		tile_stack.append(2) # Corner
	for i in 5:
		tile_stack.append(3) # Dead end
	for i in 7:
		tile_stack.append(4) # Three ways
	# Traps
	for i in range(5, 22):
		# 5-9 : demon | 10-14 : spikes | 15-19 : tunnel | 20-24 : goblin
		tile_stack.append(i)
	# Treasures
	for i in 5:
		for j in 4:
			tile_stack.append(25+i)
	tile_stack.shuffle()


func draw_card(player_index: int) -> void:
	if not card_stack.is_empty():
		players_cards[player_index].append(card_stack.pop_back())


func draw_tile(player_index: int) -> void:
	if not tile_stack.is_empty():
		players_tiles[player_index].append(tile_stack.pop_back())
