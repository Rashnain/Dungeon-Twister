extends Control


@onready var message: RichTextLabel = %Message
@onready var back_button: Button = %BackButton
@onready var continue_button: Button = %ContinueButton


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Input.is_action_just_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			if message.text.begins_with("End of game"):
				_on_back_button_pressed()
			else:
				_on_continue_button_pressed()


func _on_continue_button_pressed() -> void:
	visible = false
	back_button.visible = false
	continue_button.visible = false
	get_tree().paused = false


func _on_back_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
