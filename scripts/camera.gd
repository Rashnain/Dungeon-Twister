extends Camera2D


var target_position: Vector2 = position
var pressed: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_mouse_over_a_button():
			pressed = true
			Input.set_default_cursor_shape(Input.CursorShape.CURSOR_MOVE)
		else:
			pressed = false
			Input.set_default_cursor_shape()

	if event is InputEventMouseMotion and pressed:
			target_position -= event.relative


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		target_position.x -= 50 * delta * 7.5
	if Input.is_action_pressed("ui_right"):
		target_position.x += 50 * delta * 7.5
	if Input.is_action_pressed("ui_up"):
		target_position.y -= 50 * delta * 7.5
	if Input.is_action_pressed("ui_down"):
		target_position.y += 50 * delta * 7.5

	position = lerp(position, target_position, 7.5 * delta)


func is_mouse_over_a_button() -> bool:
	for button: BaseButton in get_tree().root.find_children("*", "BaseButton", true, false):
		if button.is_hovered():
			return true
	return false
