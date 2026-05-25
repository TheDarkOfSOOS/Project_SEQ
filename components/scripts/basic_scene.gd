class_name SceneManager extends Node2D

var player : Player
# variabile di controllo per tenere il personaggio selezionato tra le scene
var selected_character 
var connected : bool = false
# serve come indice per scorrere i tileset
var boss_defeted_count : int = 0
# tileset istanziato attualmente
var active_tileset : Node2D
# container dei nemici attualmente istanziato
var active_enemy_container : Node2D
# tutti i tipi di attacco
@onready var Attack_Types = get_tree().get_first_node_in_group("gm").Attack_Types

# il nodo canvaslayer serve per fissare la gui allo schermo
@onready var canvas_layer : CanvasLayer = find_child("CanvasLayer") 
# contenitore della gui della scena
@onready var gui : Control = canvas_layer.find_child("GUI")
# contenitore della gui di game over
@onready var game_over_container : MarginContainer = gui.find_child("GameOver_container")
@onready var game_over_retry = $CanvasLayer/GUI/GameOver_container/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Retry
# contenitore della gui del combattimento
@onready var round_gui : Control = canvas_layer.find_child("Round_GUI")
# music player che contiene le ost
@onready var ost_player : AudioStreamPlayer = $Ost_player
# variabile che contiene la gui specifica per quel player
var player_gui
@onready var powerup_handler : Node = $Powerup_handler

# percorso che porta al nodo del camera follower
var camera_follower : String = "res://scenes/miscellaneous/camera_follower.tscn"

# array che contiene i tileset
var tilesets : Array[String] = [
						"res://scenes/tilemaps/gray_tile_map.tscn",
						"res://scenes/tilemaps/deep_forest_2_tilemap.tscn",
						"res://scenes/tilemaps/deep_forest_tile_map.tscn",
						"res://scenes/tilemaps/forest_2_tilemap.tscn",
						"res://scenes/tilemaps/forest_tile_map.tscn",
						]

var portal_scene = preload("res://scenes/miscellaneous/travel_portal.tscn")
var portal

func _ready():
	#Engine.time_scale = 0.5
	#Engine.physics_ticks_per_second = 100
	
	Menu.untangle_player.connect(self._on_untangle_player)
	
	var temp : Array
	for i in tilesets.size():
		temp.append(i)
	
	#temp.shuffle()
	
	var new_tileset_order : Array[String]
	
	for i in temp:
		new_tileset_order.append(tilesets[i])
	
	tilesets = new_tileset_order
	
	# Rendo il menu non apribile
	Menu.game_status = Menu.GAME_STATUSES.unopenable
	# istanzio il tileset e lo salvo
	active_tileset = load(tilesets[boss_defeted_count]).instantiate()
	# salvo il riferimento al container dei nemici attivo
	active_enemy_container = active_tileset.find_child("Enemy_container")
	# salvo il riferimento allo scene manager al container
	active_enemy_container.scene_manager = self
	# collego i veri segnali
	active_enemy_container.round_changed.connect(round_gui._on_round_changed)
	active_enemy_container.boss_defeted.connect(self._on_boss_defeted)
	active_enemy_container.connect_boss_with_GUI.connect(round_gui._on_boss_spawned)
	# collego i segnali dei power-ups
	round_gui.powerup_spawnable.connect(active_enemy_container._on_powerup_spawnable)
	active_enemy_container.instantiate_pickup.connect(powerup_handler._on_instantiate_pickable)
	powerup_handler.spawn_pickable.connect(active_enemy_container._on_powerup_handler_spawn_pickable)
	# aggiungo il tileset alla scena
	self.call_deferred("add_child", active_tileset, true)
	
func _process(_delta):
	## stampa dei possibili output di danni per la formula, utile per testarla
	#if Input.is_action_just_pressed("base_atk"):
		#for i in range(10):
			#var atk = randi_range(30, 999)
			#var skill_atk = randi_range(30, 999)
			#var tem = randi_range(30, 999)
			#print("atk: "+str(atk)+", skill atk: "+str(skill_atk)+", tem: "+str(tem)+" =  "+str(self.calculate_dmg(atk, skill_atk, tem, 0, 1, null)))
	
	if player != null:
		if not active_enemy_container.fighting:
			connected = false
		if active_enemy_container.fighting and not connected:
			connect_enemies_with_player()
			connected = true

#ISTANZIA IL PLAYER IN BASE ALLA SELEZIONE DEL NODO GUI
	# params(
	# character: il personaggio scelto passato dal GM
	# )
	
func _on_gui_select_character(character):
	var player_scene
	selected_character = character
	if selected_character == "jack":
		player_scene = load("res://scenes/characters/jack.tscn")
	elif selected_character == "tyrone":
		player_scene = load("res://scenes/characters/tyrone.tscn")
	
	# istanzio e salvo la scena con il personaggio scelto
	player = player_scene.instantiate()
	# metto il nome "Player" al personaggio
	player.name = "Player"
	# mi assicuro che la scale sia corretta
	player.scale = Vector2(1.0, 1.0)
	# salvo il riferimento allo scene manager al player
	player.scene_manager = self
	
	# carico ed istanzio la telecamera
	var new_camera : CameraFollower = load(camera_follower).instantiate()
	# e gli passo il riferimento al player
	new_camera.player = player

	activate_player_GUI() # funzione per attivare le GUI
	connect_enemies_with_player() # connetto i nemici e il player
	# passo i riferimenti del player e del powerup handler a vicenda
	powerup_handler.player = player
	player.powerup_handler = powerup_handler
	
	gui.visible = false
	canvas_layer.get_child(0).visible = true
	# setto il menu del dungeon
	Menu.game_status = Menu.GAME_STATUSES.dungeon
	
	# aggiungo la camera e il player alla scena
	self.call_deferred("add_child", new_camera, true)
	self.call_deferred("add_child", player)

# METODO CHE CONNETTE I SEGNALI AL PLAYER
#	cicla ogni nodo figlio del container
#		se il nodo è di tipo "Enemy", allora collega i vari segnali

func connect_enemies_with_player(): #connette i segnali tra il player e i nemici
	for current_node in active_enemy_container.get_children(true): #cicla per ogni figlio della scena
		#se il nome del nemico contiene "Enemy"
		if current_node is Enemy: 
			current_node.scene_manager = self
			# assegno il parametro player del nemico con il player attivo
			current_node.player = player
			# segnale tra player e nemici per capire se si è in range
			player.is_in_atk_range.connect(current_node._on_player_is_in_atk_range)
			# segnale tra player e nemici per infliggere danno
			player.take_dmg.connect(current_node._on_player_take_dmg)
			# prima controllo che abbia il segnale (se non ce l'ha vuol dire che ha solo proiettili)
			if current_node.has_signal("take_dmg"):
				# segnale tra nemici e player per infliggere danno
				current_node.take_dmg.connect(player._on_enemy_take_dmg)
			current_node.shake_camera.connect(player.camera._on_player_shake_camera)
			
			# se il player ha scelto Tyrone
			if player is Tyrone: # connetto il segnale del knockback e del cambio statistiche
				player.change_stats.connect(current_node._on_change_stats)
				player.inflict_knockback.connect(current_node.init_knockback)
			elif player is Jack: # connetto il segnale del knockback
				player.inflict_knockback.connect(current_node.init_knockback)
			
			if current_node is Lich:
				for j in active_enemy_container.get_children():
					if "Spawnpoint" in j.name: 
						current_node.evocation_locations.append(j)
			
			# se il nodo è un mezzo-umano
			if current_node is Werewolf:
				for j in active_enemy_container.get_child_count(): # cicla per ogni figlio della scena
					var node = active_enemy_container.get_child(j) # prendo il singolo nodo
					if "Enemy" in node.name: # se il nome del nemico contiene "Enemy"
						current_node.change_stats.connect(node._on_change_stats) # connetto il segnale ad ogni nemico
			
			if current_node is Fae:
				current_node.flee_locations = active_enemy_container.markers
			
			if current_node is Centaur:
				current_node.grab_player.connect(player._on_enemy_grab)
				current_node.inflict_knockback.connect(player.init_knockback)
			
			# se il nodo è un boss
			if current_node is Boss:
				# allora connetto il segnale della barra della vita alla gui
				current_node.set_health_bar_to_gui.connect(round_gui._on_boss_set_healthbar)

# METODO CHIAMATO OGNI VOLTA CHE VIENE SPARATO UN PROIETTILE DAL PLAYER
func connect_player_projectile(projectile):
	for current_node in active_enemy_container.get_children(true): #cicla per ogni figlio del container
		#se il nodo è un "Enemy"
		if current_node is Enemy: 
			# connetto il segnale del danno
			projectile.take_dmg.connect(current_node._on_player_take_dmg)
			# connetto il segnale del knockback
			projectile.inflict_knockback.connect(current_node.init_knockback)

func calculate_dmg(strenght, atk_str, tem, pbc, efc, type, _caller):
	var crit = false
	var shake_amount = 0
	var dmg : int
	if tem <= 0:
		tem = 1
	# applico la formula del danno: (FORZA_ATTACCANTE * FORZA DELL'ATTACCO) / TEMPRA_BERSAGLIO
	dmg = round((strenght * atk_str) / tem)
	var rng = randi_range(0, 100) # genero un numero casuale tra 0 e 100
	if pbc > rng: # se la probabilità brutto colpo è più alta del numero generato (esempio: 30 > 20)
		# aumento il danno in base all'efficienza del colpo critico (es. 15 * 1.5 = 15 + 7.5 = 22.5 = 23)
		dmg = round(dmg * efc)
		crit = true
	
	# controllo il tipo di attacco
	if type == Attack_Types.PHYSICAL:
		shake_amount = dmg / 3
		if shake_amount <= 0:
			shake_amount = 5
	return [dmg, crit, shake_amount]

# DIGEST DEL SEGNALE DELLA PLAYER_GUI CHE NOTIFICA QUANDO GLI HP DEL PLAYER SCENDONO A 0
func _on_player_death():
	ost_player.get_stream_playback().switch_to_clip_by_name(&"game_over")
	gui.visible = true # la GUI diventa visibile
	game_over_container.visible = true # rendo visibile il game over
	player_gui.visible = false # nascondo la gui del player
	Menu.game_status = Menu.GAME_STATUSES.unopenable # Azione piu' forte di quel che si pensi, non usarlo a cuor leggero
	# metto il focus sul pulsante riprova nell menu di game over
	game_over_retry.grab_focus()

func activate_player_GUI():
	# istanzio la gui in base al player scelto
	if player is Tyrone:
		player_gui = load("res://scenes/GUI/tyrone_gui.tscn").instantiate()
	elif player is Jack:
		player_gui = load("res://scenes/GUI/jack_gui.tscn").instantiate()
		player.launched_flashbang.connect(player_gui._on_jack_flashbang)
		
	# connetto il segnale dell'enemy_container attivo con il digest _on_get_healed del player
	active_enemy_container.heal_between_rounds.connect(player._on_get_healed)
	
	player_gui.player = player
	player_gui.player_death.connect(self._on_player_death)
	player_gui.max_health = player.default_vit
	# connetto il segnale del player al digest della GUI 
	# per aggiornare la GUI al variare della vita
	player.set_health_bar.connect(player_gui._on_player_set_health_bar)
	# per aggiornare la GUI in caso di cambi di cooldown
	player.update_gui_cooldowns.connect(player_gui._on_update_cooldowns)
	
	# aggiungo la gui alla scena
	canvas_layer.add_child(player_gui,true)

func _on_boss_defeted():
	# istanzio il portale
	portal = portal_scene.instantiate()
	# metto il portale dove è spawnato il boss
	portal.global_position = active_enemy_container.boss_spawner.global_position
	# assegno il paramentro player del portale al layer attivo
	portal.player = player
	# collego il segnale del portale allo scene manager per cambiare stage
	portal.change_stage.connect(self._on_change_stage)
	add_child(portal,true)

func _on_change_stage():
	# aggiorno il numero di boss sconfitti
	boss_defeted_count += 1
	
	# libero le variabili attive per riassegnarle
	active_tileset.queue_free()
	active_enemy_container.free()
	
	active_tileset = load(tilesets[boss_defeted_count % tilesets.size()]).instantiate()
	# istanzio un nuovo nodo tileset e assegno quest'ultimo alla variabile del tileset attivo
	active_enemy_container = active_tileset.find_child("Enemy_container")
	
	# collego tutti i segnali del container ai rispettivi digest
	active_enemy_container.round_changed.connect(round_gui._on_round_changed)
	active_enemy_container.boss_defeted.connect(self._on_boss_defeted)
	active_enemy_container.connect_boss_with_GUI.connect(round_gui._on_boss_spawned)
	active_enemy_container.heal_between_rounds.connect(player._on_get_healed)
	active_enemy_container.scene_manager = self
	
	round_gui.powerup_spawnable.connect(active_enemy_container._on_powerup_spawnable)
	active_enemy_container.instantiate_pickup.connect(powerup_handler._on_instantiate_pickable)
	powerup_handler.spawn_pickable.connect(active_enemy_container._on_powerup_handler_spawn_pickable)

	add_child(active_tileset, true)

	player.global_position = active_enemy_container.boss_spawner.global_position
	portal.global_position = active_enemy_container.boss_spawner.global_position

func _on_canvas_layer_child_entered_tree(_node: Node) -> void:
	if canvas_layer:
		for i in canvas_layer.get_children():
			i.visible = not i.visible

func _on_canvas_layer_child_exiting_tree(_node: Node) -> void:
	if canvas_layer:
		for i in canvas_layer.get_children():
			i.visible = not i.visible

func _on_untangle_player():
	if is_instance_valid(player):
		player.global_position = active_enemy_container.boss_spawner.global_position
