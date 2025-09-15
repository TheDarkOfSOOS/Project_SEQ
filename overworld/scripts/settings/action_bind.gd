extends HBoxContainer

# Once in a while it just want to break :/
# Do so the keybinds settings has the whole row so it can change
# To the proper value

#@onready var input_associated : String
@onready var input_name : String

@onready var text_label = %TextLabel
@onready var gp_label = %GamepadActionLabel
@onready var kb_label = %KeyboardActionLabel
@onready var btn = %ModifyKeybindButton

func _on_modify_keybind_button_pressed() -> void:
	Menu.input_reader.read_input(btn, gp_label, kb_label, input_name, true)
	release_focus()
