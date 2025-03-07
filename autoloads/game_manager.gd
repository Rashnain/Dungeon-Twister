extends Node


enum Stack { CARD, TILE }

var nr_players: int
var players_money: Array[int]
var players_pawns: Array[Sprite2D]
var players_cards: Array[Array]
var players_tiles: Array[Array]
var players_can_cancel_traps: Array[bool]
var players_skip_next_turn: Array[bool]
var players_has_treasure_boost: Array[bool]

var tile_stack: Array[int]
var card_stack: Array[int]

var tongue_twisters: Array


func _ready() -> void:
	var json_file: JSON = load("res://assets/tongue_twisters.json")
	tongue_twisters = json_file.data["list"]


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
		var pawn := Sprite2D.new()
		pawn.texture = load("res://assets/pawns/%s.png" % Pawn.get_name_from_id(i))
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


func draw(player_index: int, type: Stack, amount: int) -> int:
	var stack: Array[int]
	var player_hand: Array

	if type == Stack.TILE:
		stack = tile_stack
		player_hand = players_tiles[player_index]
	elif type == Stack.CARD:
		stack = card_stack
		player_hand = players_cards[player_index]

	var len_before := len(player_hand)

	for i in amount:
		if not stack.is_empty():
			player_hand.append(stack.pop_back())

	return len(player_hand) - len_before


func pick_random_tongue_twister() -> String:
	return tongue_twisters[randi() % len(tongue_twisters)]
