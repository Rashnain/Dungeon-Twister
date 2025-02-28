class_name Pawn


static func get_name_from_id(id: int) -> String:
	match id:
		0:
			return "car"
		1:
			return "cube"
		2:
			return "horse"
		3:
			return "pyramide"
		4:
			return "sphere"
		_:
			return "uwu"
