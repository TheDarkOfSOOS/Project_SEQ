extends VBoxContainer

@onready var keybind_row_scene = preload("res://overworld/scenes/key_container.tscn")

func _ready():
	build_input_list()

func build_input_list():
	# Free table
	for rows in self.get_children():
		rows.queue_free()
	
	# Put all events
	for input in InputMap.get_actions():
		if not input.begins_with("ui_"):
			# Look only for our personalized
			var key_row = keybind_row_scene.instantiate()
			add_child(key_row)
			key_row.text_label.text = input
			
			key_row.input_name = input
			for ev in InputMap.action_get_events(input):
				if (ev is InputEventJoypadButton) or (ev is InputEventJoypadMotion):
					key_row.gp_label.text = ev.as_text()
					#key_row.input_associated = InputMap.action_get_events(input)[0].as_text()
				else:
					key_row.kb_label.text = ev.as_text()
	print(get_children())
