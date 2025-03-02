extends ScrollContainer


@onready var instructions : Label = %Instructions

var is_up_to_date := true


func _input(event: InputEvent) -> void:
	if instructions.size.y > size.y:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			is_up_to_date = false


func _process(_delta: float) -> void:
	if instructions.size.y > size.y:
		if is_up_to_date:
			set_v_scroll(int(instructions.size.y - size.y))
		elif get_v_scroll() == instructions.size.y - size.y:
			is_up_to_date = true
