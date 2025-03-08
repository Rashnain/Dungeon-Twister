extends Node


enum Stack { CARD, TILE }

var tongue_twisters: Array
var nr_players: int
var players: Array[Player]
var tile_stack: Array[int]
var card_stack: Array[int]


func _ready() -> void:
	var json_file: JSON = load("res://assets/tongue_twisters.json")
	tongue_twisters = json_file.data["list"]


func init_game() -> void:
	# Players
	players.clear()
	var x: int = int(-(200*nr_players + 10*(nr_players-1)) / 2.0)
	for i in nr_players:
		var new_player: Player = preload("res://scenes/player.tscn").instantiate()
		var pawn := Sprite2D.new()
		pawn.texture = load("res://assets/pawns/%s.png" % Pawn.get_name_from_id(i))
		new_player.pawn = pawn
		new_player.position = Vector2i(x, -355)
		new_player.player_name = "Player %d" % [i+1]
		players.append(new_player)
		x += 200 + 10

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
		player_hand = players[player_index].tiles
	elif type == Stack.CARD:
		stack = card_stack
		player_hand = players[player_index].cards

	var len_before := len(player_hand)

	for i in amount:
		if not stack.is_empty():
			player_hand.append(stack.pop_back())

	return len(player_hand) - len_before


func update_stats() -> void:
	for player in players:
		player.update()


func pick_random_tongue_twister() -> String:
	return tongue_twisters[randi() % len(tongue_twisters)]
