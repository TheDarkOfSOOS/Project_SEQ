class_name GameManager extends Node
# To call game_manager, please use:
# get_tree().get_first_node_in_group("gm")

enum Attack_Types {PHYSICAL, PROJECTILE}
const Status_Icons = {
	"weakness" : "res://components/icons/weakness_icon.png",
	"strenght" : "res://components/icons/strenght_icon.png",
	"fragility" : "res://components/icons/fragility_icon.png",
	"vigor" : "res://components/icons/vigor_icon.png",
	"slowdown" : "res://components/icons/slowdown_icon.png",
	"swiftness" : "res://components/icons/swiftness_icon.png",
	"luck" : "res://components/icons/luck_icon.png",
	"unluck" : "res://components/icons/unluck_icon.png"
}

@onready var root : Window = get_node("/root/")

var idle_timeout = 3  # secondi
var last_input_time = Time.get_ticks_msec()
var is_cursor_hidden = false

func _ready():
	# Depends on starting scene
	Menu.game_status = Menu.GAME_STATUSES.unopenable
	#get_node("/root/").set_size(DisplayServer.screen_get_size())dwaq

func _process(_delta):
	if Input.is_action_just_pressed("pause") and Menu.game_status != Menu.GAME_STATUSES.unopenable:
		Menu.pause_game()

	if Input.is_action_just_pressed("fullscreen_toggle"):
		fullscreen()
	
	if Input.get_last_mouse_velocity():
		last_input_time = Time.get_ticks_msec()
	
	if Time.get_ticks_msec() - last_input_time > idle_timeout * 1000 and not is_cursor_hidden:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		is_cursor_hidden = true
	
	elif Time.get_ticks_msec() - last_input_time < idle_timeout * 1000 and is_cursor_hidden:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		is_cursor_hidden = false
	

func load_dungeon():
	Engine.time_scale = 1.0
	Menu.game_status = Menu.GAME_STATUSES.dungeon
	get_child(0).ost_player.stop()
	var selected_character # attributo da passare
	add_child(load("res://scenes/basic_scene.tscn").instantiate(), true)
	if get_child(0).selected_character: # se l'attributo che devo passare è presente
		selected_character = get_child(0).selected_character # lo setto sul nuovo nodo
		get_child(-1)._on_gui_select_character(selected_character) # ed istanzio il nodo corrispondente
	get_child(0).queue_free()

func load_map():
	Engine.time_scale = 1.0
	Menu.game_status = Menu.GAME_STATUSES.overworld
	get_child(0).ost_player.stop()
	var selected_character # attributo da passare
	add_child(load("res://overworld/scenes/maps/default_map.tscn").instantiate(), true)
	if get_child(0).selected_character: # se l'attributo che devo passare è presente
		selected_character = get_child(0).selected_character # lo setto sul nuovo nodo
		get_child(get_child_count()-1)._on_gui_select_character(selected_character) # ed istanzio il nodo corrispondente
	get_child(0).queue_free()
	
func fullscreen():
	if DisplayServer.window_get_mode(0) != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func force_delay(duration : float) -> void:
	#print("entrato, "+str(duration))
	await get_tree().create_timer(duration, false, false, true).timeout
