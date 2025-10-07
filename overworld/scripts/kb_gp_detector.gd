extends Node

var using_gamepad : bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if (event is InputEventKey) \
	or (event is InputEventMouseMotion) \
	or (event is InputEventMouseButton):
		using_gamepad = false
	elif event is InputEventJoypadButton:
		using_gamepad = true
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) >= 0.5:
			using_gamepad = true
	#print(using_gamepad)

func is_event_gamepad(ev) -> bool:
	return (ev is InputEventJoypadButton) or (ev is InputEventJoypadMotion)
