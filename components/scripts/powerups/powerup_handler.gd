extends Node

var player : Player

var active_powerups : Array
var possible_powerups : Array

var pickable_scene = preload("res://scenes/powerup/powerup_pickable.tscn")

signal spawn_pickable(node)

func _ready() -> void:
	# Funzione che legge le risorse nella cartella dei powerups
	var path = "res://components/resources/powerups/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				possible_powerups.append(load(path + file_name))
			file_name = dir.get_next()

# Funzione per istanziare il pickable dei powerups
func _on_instantiate_pickable():
	add_child(pickable_scene.instantiate())
	var pickable = get_child(-1)
	pickable.handler = self
	pickable.player = player
	pickable.canvas_layer = get_parent().canvas_layer
	##DEBUG
	#for i in range(3):
		#var pulled_powerup = possible_powerups[2]
		#var pulled_rar = PowerupStats.rar.find_key(randi_range(i, pulled_powerup.max_rarity))
		#
		#pickable.pulled_powerups.append(pulled_powerup)
		#pickable.pulled_rarities.append(PowerupStats.rar.get(pulled_rar))
	for i in range(3):
		var pulled_powerup = possible_powerups.pick_random()
		var pulled_rar = PowerupStats.rar.find_key(randi_range(0, pulled_powerup.max_rarity))
		
		if active_powerups.has(pulled_powerup):
			var prev_rar = active_powerups[active_powerups.find(pulled_powerup)].max_rarity
			
			if not prev_rar == PowerupStats.rar.legendary:
				pulled_rar = randi_range(prev_rar+1, PowerupStats.rar.legendary)
			else:
				pulled_rar = PowerupStats.rar.legendary
			
			pulled_rar = PowerupStats.rar.find_key(pulled_rar)
		
		pickable.pulled_powerups.append(pulled_powerup)
		pickable.pulled_rarities.append(PowerupStats.rar.get(pulled_rar))
	
	emit_signal("spawn_pickable", pickable)

# Funzione che viene chiamata quando viene raccolto un powerup
func new_powerup(resource : Powerup, pulled_rarity : PowerupStats.rar) -> void:
	if not active_powerups.has(resource):
		resource.max_rarity = pulled_rarity
		active_powerups.append(resource)
		activate_powerup(resource)
		
		if resource.custom_handler:
			add_child(resource.custom_handler.instantiate())
	else:
		activate_powerup(resource, true)
		resource.max_rarity = pulled_rarity
		activate_powerup(resource)

# Funzione per attivare per la prima volta un powerup
func activate_powerup(powerup : Powerup, delete : bool = false) -> void:
	if powerup.p_name == "Robert":
		if not delete:
			powerup.boost = increase_stat_by_percentage(player.default_vit, rarity_power(powerup))
		else:
			powerup.boost *= -1
		player.default_vit += round(powerup.boost)
		if not player.current_vit + powerup.boost <= 0:
			player.emit_signal("set_health_bar", player.current_vit)
		player.current_vit += round(powerup.boost)
		player.emit_signal("set_health_bar", player.current_vit)
		
		powerup.boost = abs(powerup.boost)
	
	elif powerup.p_name == "Alvin":
		powerup.boost = rarity_power(powerup)
	
	elif powerup.p_name == "Abigail":
		powerup.boost = rarity_power(powerup)
	
	elif powerup.p_name == "John":
		if not delete:
			powerup.boost = increase_stat_by_percentage(player.sprite_animation_speed, rarity_power(powerup))
		else:
			powerup.boost *= -1
		player.sprite_animation_speed += powerup.boost
		player.sprite.speed_scale = player.sprite_animation_speed
		
		powerup.boost = abs(powerup.boost)

# Funzione d'appoggio che dati una base e una percentuale, essa viene incrementata
func increase_stat_by_percentage(base : float, perc : float) -> float:
	var a : float = perc * base / 100
	return a

# Funzione d'appoggio che data una risorsa calcola il boost della rarità pullata
func rarity_power(resource : Powerup) -> float:
	var a : float = resource.base + (resource.step * resource.max_rarity)
	return a

# Funzione che viene chiamata ogni volta che deve essere attivato un powerup
func apply_powerup_boost(powerup_name : String, param : Array = [null]) -> Variant:
	for i in active_powerups:
		if powerup_name == i.p_name:
			if i.p_name == "Alvin":
				for j in param.size():
					var tmp = param.pop_front()
					tmp = increase_stat_by_percentage(tmp, i.boost)
					param.push_back(tmp)
				return param
			elif i.p_name == "Abigail":
				return increase_stat_by_percentage(param.pop_front(), i.boost)
			elif i.p_name == "John":
				return increase_stat_by_percentage(param.pop_front(), rarity_power(i))
			
	return null
