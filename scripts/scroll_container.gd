extends ScrollContainer


@onready var instructions : Label = %Instructions

var is_up_to_date := true


func _input(event: InputEvent) -> void:
	if instructions.size.y > 225:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			is_up_to_date = false


func _process(_delta: float) -> void:
	if instructions.size.y > 225:
		if is_up_to_date:
			set_v_scroll(instructions.size.y - 225)
		elif get_v_scroll() == instructions.size.y - 225:
			is_up_to_date = true
