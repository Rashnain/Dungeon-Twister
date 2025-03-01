extends Camera2D


var target_position: Vector2 = position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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

	position = lerp(position, target_position, 10 * delta)
