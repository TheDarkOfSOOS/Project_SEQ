class_name Centaur extends Enemy

var scene_manager : Node2D

var grab_position

signal take_dmg(str, atk_str, sec_stun, pbc, efc, type, sender)
signal got_grabbed(is_grabbed)
signal grab_player(has_grabbed, grab_position_marker, sender)
signal change_stats(stat, amount, time_duration, ally_sender)
signal inflict_knockback(amount, force, sender)
signal shake_camera(shake, strenght)

enum Possible_Attacks {IDLE, HALBERD, SPRINT, TEMPERANCE}
var choosed_atk

var sprinting = false
var is_performing_grab = false

var target_location
var origin
var first_direction
var first_enter = true

@export var halberd_force = 10
@export var halberd_stun_time = 2
@onready var halberd_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL
@export var sprint_duration = 5
@export var sprint_force = 17
@export var sprint_multiplyer = 400
@export var sprint_knockback_amount = 400
@export var sprint_knockback_force = 9.2
@onready var sprint_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL
@export var temperance_changed_stat = "vigor"
@export var temperance_amount = 60
@export var temperance_duration = 50

var SPRITE_FLIP : bool
var UPPER_BODY_COLLIDER_X : float
var BODY_COLLIDER_X : float
var HALBERD_COLLIDER_X : float
var SPRINT_COLLIDER_X : float

@onready var safe_timer : Timer = $Safe_timer

@onready var body_collider : CollisionShape2D = $Body_collider
@onready var upper_body_collider : CollisionShape2D = $Body_collider_upper

@onready var halberd_collider : CollisionShape2D = $Halberd_area/Collider

@onready var sprint_collider : CollisionShape2D = $Sprint_area/Collider
@onready var sprint_duration_timer : Timer = $Sprint_area/Sprint_duration
@onready var sprint_reset_collider : CollisionShape2D = $Reset_sprint_area/Collision

@onready var update_atk_timer : Timer = $Update_Atk

@onready var grab_position_marker : Marker2D = $Grab_position
@onready var animation_player : AnimationPlayer = $AnimationPlayer

@onready var halberd_cooldown : Timer = $Halberd_cooldown
@onready var sprint_cooldown : Timer = $Sprint_cooldown
@onready var temperance_cooldown : Timer = $Temperance_cooldown

var player_in_atk_range : bool = false

#METODO CHE PARTE QUANDO VIENE ISTANZIATO IL NODO
	#setta la vita attuale a quella massima
	#imposta il valore massimo della barra della salute al massimo
	#setta la barra della salute

func _ready():
	var stats : Resource = load("res://components/resources/stats/centaur_stats.tres")
	load_stats(stats)
	
	SPRITE_FLIP = sprite.flip_h
	BODY_COLLIDER_X = body_collider.position.x
	UPPER_BODY_COLLIDER_X = upper_body_collider.position.x
	HALBERD_COLLIDER_X = halberd_collider.position.x
	SPRINT_COLLIDER_X = sprint_collider.position.x
	
	sprites_to_flip = [ 
		sprite, SPRITE_FLIP
	]
	
	nodes_to_flip = [ 
		upper_body_collider, UPPER_BODY_COLLIDER_X,  
		body_collider, BODY_COLLIDER_X,
		halberd_collider, HALBERD_COLLIDER_X,  
		sprint_collider, SPRINT_COLLIDER_X
	]
	
	healthbar.max_value = default_vit
	set_health_bar()
	sprite.play("idle")
	set_idle()

#METODO CHE VIENE PROCESSATO PER FRAME
	#controlla se il player è entrato in area e si può muovere
		#allora si muove
	#altrimenti se il player NON è entrato in area e si può muovere
		#allora comincia a vagare
	#controlla se è grabbato
		#allora fa partire il metodo grab()

func _physics_process(delta):
	if not is_performing_grab and (animation_player.current_animation == "marker_movement" or animation_player.current_animation == "marker_movement_flip"):
		emit_signal("grab_player", false, null, null)
	if knockbacked:
		apply_knockback(delta)
	elif sprinting:
		sprint_to_target()
		if sprint_duration_timer.time_left == sprint_duration/2:
			sprint_reset_collider.set_deferred("disabled", false)
	elif is_instance_valid(player) and moving:
		chase_player()
		if choosed_atk == Possible_Attacks.HALBERD and halberd_cooldown.is_stopped():
			halberd()
		if choosed_atk == Possible_Attacks.SPRINT and sprint_cooldown.is_stopped():
			sprint()
		if choosed_atk == Possible_Attacks.TEMPERANCE and temperance_cooldown.is_stopped():
			temperance()
	elif not is_instance_valid(player) and not moving:
		set_idle()
	elif not is_instance_valid(player) and moving:
		sprite.play("idle")
	elif grabbed:
		is_grabbed()

func sprint_to_target():
	if is_instance_valid(player):
		var direction = global_position.direction_to(target_location)
		
		if first_enter:
			first_direction = direction
			first_enter = false
		
		if global_position.distance_to(origin) >= target_location.distance_to(origin):
			direction = first_direction
		
		if direction.x > 0:
			flip(true)
		else:
			flip(false)
		
		velocity = direction * (current_des + sprint_multiplyer)
		move_and_slide()

func choose_atk():
	var rng = randi_range(0,100)
	if rng >= 0 and rng < 40:
		choosed_atk = Possible_Attacks.HALBERD
	elif rng >= 40 and rng < 80:
		choosed_atk = Possible_Attacks.SPRINT
	else:
		choosed_atk = Possible_Attacks.TEMPERANCE
	
	#choosed_atk = Possible_Attacks.SPRINT
	
#DIGEST DEL SEGNALE DEL PLAYER "take_dmg"
#{
#	PARAMETRI
#	int atk_state: DEPRECATO
#	int dmg: quantità del danno inflitto
#	float sec: tempo dello stun
#}
#	se il nodo è in range e non è grabbato
#		allora sottraggo alla vita il danno
#		setto la barra della vita con il nuovo valore
#		# print di debug #
#		impedisco al nodo di muoversi mentre viene attaccato
#		imposto il tempo di stun con il parametro passato
#		faccio partire il timer dello stun
func _on_player_take_dmg(atk_str, skill_str, stun_sec, atk_pbc, atk_efc, type, sender):
	if is_in_atk_range and !grabbed:
		var dmg_info = scene_manager.calculate_dmg(atk_str, skill_str, self.current_tem, atk_pbc, atk_efc, type, self)
		var dmg = dmg_info[0]
		show_hitmarker("-" + str(dmg), dmg_info[1], hitmarker_spawnpoint)
		current_vit -= dmg
		set_health_bar()
		if dmg > 0:
			emit_hit_particles(sender)
			hit_flash_player.stop()
			hit_flash_player.play("hit_flash")
			emit_signal("shake_camera", true, dmg_info[2])
		if sprinting and dmg >= 25:
			sprinting = false
		elif (dmg >= 30 or dmg <= 0) and stun_sec > 0:
			sprint_collider.set_deferred("disabled", true)
			is_performing_grab = false
			moving = false
			stun_timer.wait_time = stun_sec
			stun_timer.start()
			safe_timer.start()
			sprite.play("damaged")

#DIGEST DEL SENGALE DEL PLAYER "grab"
#{
#	PARAMETRI
#	boolean is_been_grabbed: controlla se il segnale è di entrata o di uscita dalla grab
#	booelan is_flipped: indica se il player è flippato o meno
#}
#se il segnale è di grab, il nodo non è già grabbato e il nodo è in range
#	faccio ricevere un danno al nodo
#	tolgo la possibilità di muoversi del nodo
#	setto il grabbed a true
#	lo sprite diventa invisibile
#	disattivo le collisioni
#se il segnale è di uscita dalla grab e il nodo è grabbato
#	il nodo potrà di nuovo muoversi
#	setto il grabbed a false
#	se il nodo è flipped
#		spinge il nodo a sinistra di 450
#	altrimenti
#		spinge il nodo a destra di 450
#	lo sprite diventa visibile
#	faccio partire un timer per risettare le collisioni, se le riabilito insieme avviene un bug
func _on_player_grab(is_been_grabbed, _is_flipped, _grab_position_marker):
	if is_been_grabbed and !grabbed and is_in_atk_range:
		set_idle()
		sprite.play("damaged")
		update_atk_timer.stop()
		moving = false
		grabbed = true
		body_collider.set_deferred("disabled", true)
		grab_position = grab_position_marker
		
		if player.char_name == "Nathan":
			emit_signal("got_grabbed", true)
			healthbar.visible = false
		
	if !is_been_grabbed and grabbed:
		set_idle()
		grabbed = false
		body_collider.set_deferred("disabled", false)
		is_in_atk_range = true
		init_knockback(450, 0.5, player.global_position)
		is_in_atk_range = false
		
		if player.char_name == "Nathan":
			emit_signal("got_grabbed", false)
			sprite.rotation_degrees = 0;
			healthbar.visible = true

#METODO CHE TELETRASPORTA IL NODO NELLA POSIZIONE DEL PLAYER DURANTE LA GRAB
#	setto la posizione uguale a quella del player
func is_grabbed():
	flip((player.position - position).normalized())
	position = grab_position.global_position

#DIGEST DEL TIMER "Stun"
#	setto il movimento a true
func _on_stun_timeout():
	choosed_atk = Possible_Attacks.IDLE
	set_idle()

func _on_sprite_2d_animation_finished() -> void:
	if sprite.animation == "charging_sprint":
		sprinting = true
		moving = false
		target_location = player.global_position
		origin = global_position
		flip((target_location - global_position).normalized())
		upper_body_collider.set_deferred("disabled", true)
		sprint_collider.set_deferred("disabled", false)
		sprint_duration_timer.start(sprint_duration)
		sprite.play("sprint")
		update_atk_timer.stop()
	elif sprite.animation != "damaged":
		set_idle()

func _on_sprite_2d_frame_changed() -> void:
	if sprite.animation == "grab" and sprite.frame == 5:
		finish_grab()
	if sprite.animation == "halberd" and (sprite.frame == 4 or sprite.frame == 8) and player_in_atk_range:
		emit_signal("take_dmg", current_str, halberd_force, halberd_stun_time, current_pbc, current_efc, halberd_type, self)
	if sprite.animation == "temperance" and sprite.frame == 2:
		_on_change_stats(temperance_changed_stat, temperance_amount, temperance_duration, true)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	is_performing_grab = false
	emit_signal("grab_player", false, null, null)

func halberd():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and not sprinting and player_in_atk_range:
		moving = false
		safe_timer.start()
		sprite.play("halberd")
		update_atk_timer.stop()
	halberd_cooldown.start()

func sprint():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and not sprinting:
		sprite.play("charging_sprint")
		moving = false
		safe_timer.start()
		first_enter = true
		update_atk_timer.stop()
	sprint_cooldown.start()

func finish_grab() -> void:
	emit_signal("grab_player", false, null, null)
	is_performing_grab = false
	emit_signal("take_dmg", current_str, sprint_force, 0, current_pbc, current_efc, sprint_type, self)
	emit_signal("inflict_knockback", sprint_knockback_amount, sprint_knockback_force, self.global_position)

func temperance():
	if stun_timer.is_stopped() and not grabbed and not sprinting:
		sprite.play("temperance")
		moving = false
		safe_timer.start()
		update_atk_timer.stop()
	temperance_cooldown.start()

func _on_sprint_duration_timeout() -> void:
	set_idle()

func _on_halberd_area_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_atk_range = true

func _on_halberd_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_atk_range = false

func _on_sprint_area_body_entered(body: Node2D) -> void:
	if body == player and sprinting and not player.grabbed:
		sprint_collider.set_deferred("disabled", true)
		sprint_reset_collider.set_deferred("disabled", true)
		sprint_duration_timer.stop()
		sprinting = false
		if sprite.flip_h:
			animation_player.play("marker_movement_flip")
		else:
			animation_player.play("marker_movement")
		sprite.play("grab")
		emit_signal("grab_player", true, grab_position_marker, self)
		is_performing_grab = true
	elif body is TileMapLayer and not is_performing_grab:
		set_idle()

func _on_reset_sprint_area_body_entered(body: Node2D) -> void:
	if body is TileMapLayer or body == player:
		set_idle()

func _on_sprint_area_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.

#DIGEST CHE PERMETTE DI FAR RIPARTIRE IL MOVIMENTO
func set_idle():
	if not knockbacked:
		moving = true
		sprinting = false
		is_performing_grab = false
		choosed_atk = Possible_Attacks.IDLE
		sprite.play("idle")
		upper_body_collider.set_deferred("disabled", false)
		halberd_collider.set_deferred("disabled", false)
		sprint_collider.set_deferred("disabled", true)
		sprint_reset_collider.set_deferred("disabled", true)
		sprint_duration_timer.stop()
		safe_timer.stop()
		update_atk_timer.start()

func _on_safe_timer_timeout() -> void:
	set_idle()

# //////////// AREA COMUNE TRA NODI //////////// #

func _on_update_atk_timeout():
	choose_atk()
	update_atk_timer.start()

func _on_knockback_reset():
	super._on_knockback_reset()
	if stun_timer.is_stopped():
		set_idle()
