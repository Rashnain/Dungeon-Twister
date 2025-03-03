extends ScrollContainer


@onready var instructions: Label = %Instructions

var is_up_to_date := true
var scroll_bar_pressed := false


func _input(event: InputEvent) -> void:
	if instructions.size.y > size.y:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				is_up_to_date = false
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					var origin: Vector2 = global_position
					origin.x += size.x - 8
					if Rect2(origin, Vector2(8, size.y)).has_point(get_global_mouse_position()):
						scroll_bar_pressed = true
						is_up_to_date = false
				else:
					scroll_bar_pressed = false


func _process(_delta: float) -> void:
	if scroll_bar_pressed: return

	if is_up_to_date:
		set_v_scroll(int(instructions.size.y - size.y))
	elif get_v_scroll() == instructions.size.y - size.y:
		is_up_to_date = true
