extends Camera2D


var target_position: Vector2 = position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not Game.is_mouse_over_a_button():
		if event.pressed:
			Input.set_default_cursor_shape(Input.CursorShape.CURSOR_MOVE)
		else:
			print(Game.is_mouse_over_a_button())
			Input.set_default_cursor_shape()

	if event is InputEventMouseMotion:
		if Input.get_current_cursor_shape() == Input.CursorShape.CURSOR_MOVE:
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
