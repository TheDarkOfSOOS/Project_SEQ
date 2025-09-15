extends CanvasLayer

enum GAME_STATUSES{
	dungeon,
	overworld,
	unopenable
}

@onready var first_menu = %FirstMenu
@onready var quest_menu = %QuestMenu
@onready var debug_menu = %DebugMenu
@onready var settings_menu = %SettingsMenu
@onready var audio_menu = %AudioMenu
@onready var input_menu = %InputMenu
@onready var debug_back_button = %DebugBackButton
@onready var settings_back_button = %SettingsBackButton
@onready var audio_back_button = %AudioBackButton
@onready var input_back_button = %InputBackButton
@onready var continue_button = %ContinueButton
@onready var re_open_menu_delay = %ReOpenMenuDelay
@onready var internal_menu_delay = %InternalMenuDelay
@onready var all_quest_filter = %AllQuestFilter
@onready var quest_container = %QuestContainer
@onready var pause_ost = %Pause_ost_player
@onready var input_reader = %InputReader

signal untangle_player()

var internal_menu_delay_finished : bool = true
var is_delay_finished : bool = true
var game_status : GAME_STATUSES = GAME_STATUSES.unopenable

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Default visiblity settings
	first_menu.visible = true
	quest_menu.visible = false
	debug_menu.visible = false
	settings_menu.visible = false
	# subview for settings
	audio_menu.visible = false
	input_menu.visible = false

func _input(event):
	var back_input : bool = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
	
	if back_input and first_menu.visible:
		resume_game()
	if back_input and (quest_menu.visible or debug_menu.visible or settings_menu.visible):
		back_to_first_menu()
	if back_input and (audio_menu.visible or input_menu.visible):
		back_to_settings()

func back_to_first_menu():
	quest_menu.visible = false
	debug_menu.visible = false
	settings_menu.visible = false
	first_menu.visible = true
	continue_button.grab_focus()

func back_to_settings():
	audio_menu.visible = false
	input_menu.visible = false
	settings_menu.visible = true
	settings_back_button.grab_focus()

func pause_game():
	if is_delay_finished:
		pause_ost.play()
		is_delay_finished = false
		get_tree().paused = true
		visible = true
		continue_button.grab_focus()

func resume_game():
	pause_ost.stop()
	visible = false
	get_tree().paused = false
	re_open_menu_delay.start()

func _on_continue_button_pressed():
	resume_game()

func _on_quest_button_pressed():
	quest_container.dump_quest_data()
	first_menu.visible = false
	quest_menu.visible = true
	all_quest_filter.grab_focus()

func _on_debug_button_pressed():
	first_menu.visible = false
	debug_menu.visible = true
	debug_back_button.grab_focus()

func _on_settings_button_pressed():
	first_menu.visible = false
	settings_menu.visible = true
	settings_back_button.grab_focus()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_re_open_menu_delay_timeout():
	is_delay_finished = true

func _on_escape_button_pressed():
	resume_game()
	get_tree().get_first_node_in_group("gm").load_map()

func _on_untangle_button_pressed():
	emit_signal("untangle_player")
	resume_game()
	back_to_first_menu()

func _on_audio_button_pressed():
	settings_menu.visible = false
	audio_menu.visible = true
	audio_back_button.grab_focus()

func _on_input_button_pressed():
	settings_menu.visible = false
	input_menu.visible = true
	input_back_button.grab_focus()
