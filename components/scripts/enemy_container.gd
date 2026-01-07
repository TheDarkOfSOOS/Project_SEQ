class_name Enemy_Container extends Node2D

var markers : Array = [] # array che contiene tutti i marker della scena
var active_markers : Array = [] # array che si popola allo spawnare dei nemici
# array contenente i percorsi dei nemici
var possible_enemies : Array = [
	preload("res://scenes/enemies/zombie.tscn"),
	preload("res://scenes/enemies/skeleton.tscn"),
	preload("res://scenes/enemies/giant.tscn"),
	preload("res://scenes/enemies/werewolf.tscn"),
	preload("res://scenes/enemies/fae.tscn"),
	preload("res://scenes/enemies/centaur.tscn")
	]

# [0] = Zombie
# [1] = Scheletro
# [2] = Gigante
# [3] = Lupo Mannaro
# [4] = Fata
# [5] = Centauro

# array che contiene il percorso del boss
var boss_scene : Resource = preload("res://scenes/enemies/lich.tscn")

@export var line_scene : Resource = preload("res://scenes/miscellaneous/trail_to_pickable.tscn")
var instantiated_line : Line2D
var line : Line2D

var scene_manager : SceneManager

# ogni quante ondata spawna un boss
var boss_round : int = 10

signal round_changed() # segnale che manda alla GUI per incrementare il counter
signal heal_between_rounds(amount) # segnale che manda al player per curarlo
signal boss_defeted() # segnale che manda allo scene_manager per evocare il portale
signal connect_boss_with_GUI(boss) # segnale che collega il boss alla barra della vita
signal instantiate_pickup()

var fighting : bool # flag che determina quando esistono nemici
var boss_is_defeted : bool = false # flag che determina quando il boss è stato sconfitto
var boss_spawned : bool = false # flag che determina se il boss è spawnato
var portal_spawned : bool = false # flag che determina se il portale è spawnato

var powerup_spawned : bool = true # flag che determina se è spawnato il powerup
var powerup_spawnable : bool = false # flag che determina se è spawnabile il powerup
var powerup_picked : bool = true # flag che determina se il powerup è stato raccolto

var dramatic_flag : bool = false # flag che determina se far partire lo slow motion

@onready var time_between_rounds : Timer = $Round_cooldown
@onready var boss_spawner : Marker2D = $Boss_spawner

func _ready():
	# popolo l'array con tutti gli spawnpoint
	for i in get_children():
		if "Spawnpoint" in i.name:
			markers.append(i)

#METODO CHE VIENE INVOCATO AD OGNI FRAME, CONTROLLA SE I NEMICI SONO ANCORA PRESENTI IN GAME
func _process(_delta):
	# metto le flag di controllo a falso
	fighting = false
	var boss_present = false
	var powerup_present = false
	
	# ciclo i figli del container
	for i in get_children():
		# se c'è un nemico, metto che siamo in combattimento
		if i is Enemy:
			fighting = true
		# se c'è un boss ed è il round dove è spawnato allora è presente
		if i is Boss and is_boss_round():
			boss_present = true
		# se c'è un powerup pickable, allora è presente
		if i is Powerup_Pick:
			powerup_present = true
	
	# se il boss è spawnato E il boss NON è presente, allora vuol dire che è stato sconfitto
	if boss_spawned and not boss_present:
		boss_is_defeted = true
	
	# se il powerup è spawnato E il pickable NON è presente, allora vul dire che è stato raccolto
	if powerup_spawned and not powerup_present:
		powerup_picked = true
	
	# se la linea guida esiste, allora la aggiorno
	if is_instance_valid(line):
		var new_array : Array[Vector2] = [scene_manager.player.SPRITE_REFERENCES.r["down"].global_position, boss_spawner.global_position]
		line.points = PackedVector2Array(new_array)
	
	# se il boss NON è sconfitto oppure il powerup è spawnabile e...
	if not boss_is_defeted or powerup_spawnable:
		# ...se il non si sta combattendo e non è spawnato il powerup ed è spawnabile
		if not fighting and not powerup_spawned and powerup_spawnable:
			# se non è il round del boss allora faccio partire lo slow motion
			if not is_boss_round():
				dramatic_slow_motion()
			# istanzio il pickable
			emit_signal("instantiate_pickup")
			# dico che ho spawnato il powerup
			powerup_spawned = true
			# ovviamente non è stato preso perché l'ho appena spawnato
			powerup_picked = false
			# ora non è più spawnabile
			powerup_spawnable = false
		# ...altrimenti se non si sta combattendo e il tempo tra round è finito E il powerup è stato raccolto
		elif not fighting and time_between_rounds.is_stopped() and powerup_picked:
			# se la linea è spawnata la tolgo
			if is_instance_valid(line):
				line.queue_free()
			# faccio partire lo slow motion
			dramatic_slow_motion()
			# faccio partire il tempo tra i rounds
			time_between_rounds.start()
	else: # altrimenti
		# se non è spawnato il portale e il powerup è stato raccolto
		if not portal_spawned and powerup_picked:
			# dichiaro che il boss è stato sconfitto
			emit_signal("boss_defeted")
			# e dico che il portale è spawnato
			portal_spawned = true

# DIGEST DEL TIMER CHE DETERMINA QUANDO DEVE PARTIRE UNA NUOVA ONDATA
func _on_round_cooldown_timeout():
	var player = get_parent().get_parent().player
	var heal_amount = round(player.default_vit / 10)
	emit_signal("round_changed") # invio il segnale al round_gui per incremetare l'ondata
	emit_signal("heal_between_rounds", heal_amount) # invio il segnale al player per curarsi di una certa quantità
	fighting = true # di conseguenza i nemici spawneranno quindi combatto
	dramatic_flag = true
	if is_boss_round() and not boss_is_defeted: # se è il round del boss e il boss non è stato sconfitto
		spawn_boss() # spawno il boss
		boss_spawned = true # ricordo che l'ho spawnato
	else: # altrimenti
		activate_markers() # evoco semplicemente i nemici normali

# METODO CHE ATTIVA I MARKER E SPAWNA I NEMICI IN BASE AL NUMERO DI ONDATA
func activate_markers():
	active_markers.clear() # pulisco i marker attivi così da poter popolarlo correttamente
	
	# prendo il numero di ondata dalla round_gui
	var round_count = get_parent().get_parent().round_gui.round_count
	
	# determino il numero minimo di nemici arrotondando per difetto
	var min_count = ceil(round_count/2)
	
	if min_count < 1: # se il minimo è minore di 1
		min_count = 1 # lo metto a 1
	elif min_count > markers.size(): # se è maggiore del numero massimo di marker
		min_count = markers.size() # lo metto al massimo
	
	var max_count = round_count # il massimo di nemici è uguale al numero di round
	if max_count < 1: # se il massimo è minore di 1
		max_count = 1 # lo metto a 1
	elif max_count > markers.size(): # se è maggiore del numero massimo di marker
		max_count = markers.size() # lo metto al massimo
	
	# genero randomicamente un numero compreso tra il minimo e il massimo
	# questo è il numero di nemici di questo round
	var enemy_count = randi_range(min_count, max_count)
	
	#enemy_count = markers.size()
	#enemy_count = 1
	
	# ///////////// PRINT DI DEBUG ///////////// #
	#print("round_count = " + str(round_count))
	#print("min_count = " + str(min_count))
	#print("max_count = " + str(max_count))
	#print("enemy_count = " + str(enemy_count))
	# ///////////// PRINT DI DEBUG ///////////// #
	
	for i in enemy_count: # ciclo con i < enemy_count
		var out = false # instanzio un bool sentinella
		while not out: # finché la sentinella è falsa
			var marker = markers.pick_random() # prendo un marker casuale
			if not marker in active_markers: # se il marker NON è già stato attivato
				active_markers.append(marker) # attivo il marker
				out = true # esco appena ne ho attivato uno
	
	for i in active_markers: # ciclo i marker attivi
		var out = false # instanzio un bool sentinella
		var enemy_scene # dichiaro una variabile d'appoggio
		while not out: # finché la sentinella è falsa
			enemy_scene = possible_enemies.pick_random() # prendo un nemico casuale dalla pool
			# se l'ondata è minore di 5 non istanzio nemici forti
			#if round_count < 5 and (enemy_scene == possible_enemies[2] or enemy_scene == possible_enemies[4] or enemy_scene == possible_enemies[5]): 
			#	out = false # non esco e ne seleziono un altro
			#else: # altrimenti
			out = true # seleziono il percorso
		
		var new_enemy = enemy_scene.instantiate()
		#new_enemy = possible_enemies[randi_range(0,0)].instantiate() # debug
		
		# setto la posizione del nemico spawnato al marker attivo
		new_enemy.global_position = i.position 
		
		add_child(new_enemy,true) # insanzio come nodo figlio il nemico

# METODO CHE SPAWNA IL BOSS
func spawn_boss():
	var new_boss = boss_scene.instantiate()
	new_boss.global_position = boss_spawner.position # metto la posizione del boss nel suo marker
	add_child(new_boss,true) # instanzio come nodo figlio il boss
	# segnalo alla round_gui che il boss è spawnato e glielo passo
	emit_signal("connect_boss_with_GUI", new_boss) 

# METODO CHE CONTROLLA SE E' IL ROUND IN CUI DEVE SPAWNARE IL BOSS
func is_boss_round():
	# prendo il numero di ondata dalla round_gui
	var round_count = get_parent().get_parent().round_gui.round_count 
	# se il round_count è > 0 ed è divisibile per n (ogni quanti round far spawnare il boss)
	if round_count > 0 and round_count % boss_round == 0: 
		return true # ritorno vero
	else: # altrimenti
		return false # ritorno falso

# DIGEST DEL SEGNALE CHE RESETTA IL CONTROLLO DEL POWER-UP
func _on_powerup_spawnable() -> void:
	powerup_spawnable = true
	powerup_picked = false
	powerup_spawned = false

# DIGEST DEL SEGNALE DEL POWER-UP HANDLER CHE REPARENTA IL PICKABLE
func _on_powerup_handler_spawn_pickable(node : Variant) -> void:
	node.reparent(self)
	node.global_position = boss_spawner.global_position
	instantiate_line()

# METODO PER FAR PARTIRE LO SLOW MOTION
func dramatic_slow_motion() -> void:
	if dramatic_flag:
		Engine.time_scale = 0.3
		await get_tree().create_timer(0.5).timeout
		Engine.time_scale = 1.0
		dramatic_flag = false

# METODO PER ISTANZIARE LA LINEA DA FAR SEGUIRE AL PLAYER
func instantiate_line():
	var new_array : Array[Vector2] = [scene_manager.player.SPRITE_REFERENCES.r["down"].global_position, boss_spawner.global_position]
	instantiated_line = line_scene.instantiate()
	instantiated_line.points = PackedVector2Array(new_array)
	self.add_child(instantiated_line, true)
	line = self.find_child("Line2D", true, false)
