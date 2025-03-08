class_name Player extends Control


@onready var background: ColorRect = $ColorRect
@onready var pawn_icon: TextureRect = $Pawn
@onready var name_label: Label = $Name
@onready var coins_label: Label = $Coins
@onready var cards_label: Label = $Cards
@onready var tiles_label: Label = $Tiles
@onready var skip_turn_icon: TextureRect = $SkipTurn
@onready var trap_canceller_icon: TextureRect = $TrapCanceller
@onready var treasure_booster_icon: TextureRect = $TreasureBooster

var player_name: String
var money := 0
var pawn: Sprite2D
var cards: Array[int] = []
var tiles: Array[int] = []
var skip_next_turn := false:
	set(new_value):
		skip_next_turn = new_value
		if new_value:
			skip_turn_icon.modulate = Color("ffffff")
		else:
			skip_turn_icon.modulate = Color("40404040")
var can_cancel_traps := false:
	set(new_value):
		can_cancel_traps = new_value
		if new_value:
			trap_canceller_icon.modulate = Color("ffffff")
		else:
			trap_canceller_icon.modulate = Color("40404040")
var has_treasure_boost := false:
	set(new_value):
		has_treasure_boost = new_value
		if new_value:
			treasure_booster_icon.modulate = Color("ffffff")
		else:
			treasure_booster_icon.modulate = Color("40404040")


func _ready() -> void:
	pawn_icon.texture = pawn.texture
	name_label.text = player_name


func update() -> void:
	coins_label.text = "%d" % money
	cards_label.text = "%d" % len(cards)
	tiles_label.text = "%d" % len(tiles)
