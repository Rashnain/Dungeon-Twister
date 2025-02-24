extends Node


var nr_players: int
var players_money: Array[int]
var players_pawns: Array[Pawn]
var players_cards: Array[Card]
var players_tiles: Array[Tile]
var players_can_cancel_traps: Array[bool]
var players_skip_next_turn: Array[bool]
var players_has_treasure_boost: Array[bool]

var tile_deck : Array[int]
var card_deck : Array[int]


func init_arrays():
	# Players stats
	players_money.clear()
	players_can_cancel_traps.clear()
	players_skip_next_turn.clear()
	players_has_treasure_boost.clear()
	for i in nr_players:
		players_money.append(0)
		players_can_cancel_traps.append(false)
		players_skip_next_turn.append(false)
		players_has_treasure_boost.append(false)

	# Cards
	card_deck.clear()
	for i in 10:
		for j in 3:
			card_deck.append(i)

	# Tiles
	tile_deck.clear()
	# Empty tiles
	for i in 5:
		tile_deck.append(0)
	for i in 10:
		tile_deck.append(1)
	for i in 10:
		tile_deck.append(2)
	for i in 5:
		tile_deck.append(3)
	for i in 7:
		tile_deck.append(4)
	# Traps
	for i in range(5, 9):
		for j in 5:
			tile_deck.append(i)
	# Treasures
	for i in 20:
		tile_deck.append(9)
