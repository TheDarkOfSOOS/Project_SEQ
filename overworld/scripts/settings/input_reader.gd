extends Control

@onready var action_label = %ActionLabel
@onready var back_to_menu_delay = %BackToMenuDelay
var keyboard_text : Button
var gamepad_text : Button
var action_name : String
var previous_focus : Button
var for_gamepad : bool

func _ready():
	visible = false
	set_process_input(false)

func _input(new_event):
	if (new_event is not InputEventMouseMotion):
		# TODO: NOT ALL KEYBINDS (e.g. esc, enter...)
		# TODO: Se keybind già usato, dare errore
		for ev in InputMap.action_get_events(action_name):
			if same_event(ev, new_event):
				InputMap.action_erase_event(action_name, ev)
				InputMap.action_add_event(action_name, new_event)
		stop_reading(new_event)

func read_input(prev_button, gp_label, kb_label, act_name, is_for_gamepad):
	previous_focus = prev_button
	gamepad_text = gp_label
	keyboard_text = kb_label
	for_gamepad = is_for_gamepad
	action_name = act_name
	visible = true
	previous_focus.release_focus()
	# Disable actions
	Menu.set_process_input(false)
	set_process_input(true)

func stop_reading(event):
	if KbGpDetector.is_event_gamepad(event):
		gamepad_text.text = event.as_text()
	else:
		keyboard_text.text = event.as_text()
	set_process_input(false)
	visible = false
	back_to_menu_delay.start()

func _on_back_to_menu_delay_timeout():
	Menu.set_process_input(true)
	previous_focus.grab_focus()

func same_event(ev1, ev2):
	print(ev1, ev2)
	var is_ev1_gp := KbGpDetector.is_event_gamepad(ev1)
	var res := false
	if ((ev2 is InputEventJoypadButton) or (ev2 is InputEventJoypadMotion)) \
	and is_ev1_gp:
		res = true
	if ((ev2 is InputEventKey) or (ev2 is InputEventMouseButton)) \
	and (not is_ev1_gp):
		res = true
	return res
