class_name Skeleton extends Enemy

var scene_manager : Node2D

var grab_position

var parring = false
var dying = false
var soul_out = false

@export var slice_force = 15
@export var slice_stun_time = 0.5
@onready var slice_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL

signal take_dmg(str, atk_str, sec_stun, pbc, efc, type, sender)
signal got_grabbed(is_grabbed)
signal shake_camera(shake, strenght)

var player_position

enum Possible_Attacks {IDLE, SLICE, PARRY}
var choosed_atk

var SPRITE_FLIP : bool
var BODY_COLLIDER_X : float
var BODY_COLLIDER_ROTATION : float
var SLICE_FLIP : bool
var SLICE_EFFECT_X : float
var SLICE_COLLIDER_X : float

@onready var slice_effect : AnimatedSprite2D = $Basic_atk_Area/Effect
@onready var slice_collider : CollisionShape2D = $Basic_atk_Area/Skill_collider
@onready var body_collider : CollisionShape2D = $Body_collider

@onready var parry_time : Timer = $Parry_time

@onready var soul_delay_timer : Timer = $Soul_delay_time

@onready var update_atk_timer : Timer = $Update_Atk

@onready var slash_cooldown : Timer = $Basic_atk_Cooldown
@onready var patty_cooldown : Timer = $Parry_Cooldown

var player_in_atk_range = false

#METODO CHE PARTE QUANDO VIENE ISTANZIATO IL NODO
	#setta la vita attuale a quella massima
	#imposta il valore massimo della barra della salute al massimo
	#setta la barra della salute

func _ready():
	var stats : Stats = load("res://components/resources/stats/skeleton_stats.tres")
	load_stats(stats)
	
	SPRITE_FLIP = sprite.flip_h
	BODY_COLLIDER_X = body_collider.position.x
	BODY_COLLIDER_ROTATION = body_collider.rotation_degrees
	SLICE_FLIP = slice_effect.flip_h
	SLICE_EFFECT_X = slice_effect.position.x
	SLICE_COLLIDER_X = slice_collider.position.x
	
	sprites_to_flip = [
		sprite, SPRITE_FLIP, 
		slice_effect, SLICE_FLIP
	]
	
	nodes_to_flip = [
		body_collider, BODY_COLLIDER_X,
		slice_collider, SLICE_COLLIDER_X,
		slice_effect, SLICE_EFFECT_X
	]
	
	nodes_to_flip_rotation = [
		body_collider, BODY_COLLIDER_ROTATION
	]
	
	healthbar.max_value = current_vit
	set_health_bar()
	sprite.play("idle")

#METODO CHE VIENE PROCESSATO PER FRAME
	#controlla se il player è entrato in area e si può muovere
		#allora si muove
	#altrimenti se il player NON è entrato in area e si può muovere
		#allora comincia a vagare
	#controlla se è grabbato
		#allora fa partire il metodo grab()

func _physics_process(delta):
	if dying or soul_out:
		pass
	elif parring:
		pass
	elif knockbacked:
		apply_knockback(delta)
	elif grabbed:
		pass
	elif is_instance_valid(player) and moving:
		chase_player()
		if choosed_atk == Possible_Attacks.SLICE and slash_cooldown.is_stopped():
			basic_atk()
		elif choosed_atk == Possible_Attacks.PARRY and patty_cooldown.is_stopped():
			parry()
	elif not is_instance_valid(player) and not moving:
		set_idle()
	elif not is_instance_valid(player) and moving:
		sprite.play("idle")

func choose_atk():
	var rng = randi_range(0,100)
	if rng >= 0 and rng < 10:
		choosed_atk = Possible_Attacks.IDLE
	elif rng >= 10 and rng < 55:
		choosed_atk = Possible_Attacks.SLICE
	elif rng >= 55:
		choosed_atk = Possible_Attacks.PARRY
		
	#choosed_atk = Possible_Attacks.PARRY

# -------- SIGNAL DIGEST -------- #

#DIGEST DEL SEGNALE DEL PLAYER "take_dmg"
#{
	#PARAMETRI
	#int atk_state: DEPRECATO
	#int dmg: quantità del danno inflitto
	#float sec: tempo dello stun
#}
	#se il nodo è in range e non è grabbato
		#allora sottraggo alla vita il danno
		#setto la barra della vita con il nuovo valore
		#impedisco al nodo di muoversi mentre viene attaccato
		#imposto il tempo di stun con il parametro passato
		#faccio partire il timer dello stun

func _on_player_take_dmg(atk_str, skill_str, stun_sec, atk_pbc, atk_efc, type, sender):
	if is_in_atk_range and !grabbed and not parring:
		var dmg_info = scene_manager.calculate_dmg(atk_str, skill_str, self.current_tem, atk_pbc, atk_efc, type, self)
		var dmg = dmg_info[0]
		if dmg <= 0 and soul_out:
			current_vit = 0.0001
		else:
			current_vit -= dmg
		if dmg > 0 and not dying:
			emit_hit_particles(sender)
			hit_flash_player.stop()
			hit_flash_player.play("hit_flash")
			show_hitmarker("-" + str(dmg), dmg_info[1], hitmarker_spawnpoint)
			emit_signal("shake_camera", true, dmg_info[2])
		if stun_sec > 0 and not (dying or soul_out):
			moving = false
			stun_timer.wait_time = stun_sec
			stun_timer.start()
			sprite.play("damaged")
		set_health_bar()
	
	elif is_in_atk_range and !grabbed and parring:
		show_hitmarker("Parato", false, hitmarker_spawnpoint)
		parry_time.start(0.8)

# DIGEST DEL SENGALE DEL PLAYER "grab" #

func _on_player_grab(is_been_grabbed, is_flipped, grab_position_marker):
	if is_been_grabbed and !grabbed and is_in_atk_range and not dying and not soul_out:
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
		healthbar.visible = true
		
		if player.char_name == "Nathan":
			emit_signal("got_grabbed", false)
			sprite.rotation_degrees = 0;
			healthbar.visible = true

#DIGEST DEL TIMER "Stun"
	#setto il movimento a true

func _on_stun_timeout():
	if not dying:
		choosed_atk = Possible_Attacks.IDLE
		set_idle()

#DIGEST DEL SEGNALE PROPRIO "set_health_bar", AGGIORNA LA BARRA DELLA SALUTE
	#il valore della barra diventa uguale a quello della vita attuale
	#se il valore della vita è minore o uguale a 0
		#cancello il nodo dalla scena

# OVERRIDE
func set_health_bar():
	if soul_out and current_vit <= 0:
		notify_death()
	elif current_vit <= 0 and not dying:
			set_idle()
			dying = true
			sprite.play("dying")
			soul_delay_timer.start()
	elif current_vit > default_vit:
			current_vit = default_vit
	
	healthbar.value = current_vit

# -------- SIGNAL DIGEST -------- #

#DIGEST CHE PERMETTE DI FAR RIPARTIRE IL MOVIMENTO

func set_idle():
	if not knockbacked and not grabbed and not (dying or soul_out):
		moving = true
		dying = false
		soul_out = false
		if parring:
			parring = false
		sprite.play("idle")
		slice_effect.play("idle")
		body_collider.set_deferred("disabled", false)

func _on_basic_atk_area_body_entered(body):
	if body == player:
		player_in_atk_range = true

func _on_basic_atk_area_body_exited(body):
	if body == player:
		player_in_atk_range = false

func _on_effect_animation_finished():
	if stun_timer.is_stopped() and slice_effect.animation == "effect" and not grabbed and player_in_atk_range and not (soul_out or dying):
		emit_signal("take_dmg", current_str, slice_force, slice_stun_time, current_pbc, current_efc, slice_type, self)
	slice_effect.play("idle")
	set_idle()
	
func basic_atk():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and player_in_atk_range and not parring:
		moving = false
		slice_effect.play("effect")
		sprite.play("attack")
	slash_cooldown.start()

func parry():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and player_in_atk_range and not parring:
		parring = true
		sprite.play("parry")
		parry_time.start(5)
	patty_cooldown.start()

func _on_parry_time_timeout() -> void:
	set_idle()

func _on_update_atk_timeout():
	choose_atk()
	update_atk_timer.start()

func _on_soul_delay_time_timeout():
	sprite.play("soul_spawning")

func _on_soul_respawn_time_timeout():
	dying = true
	soul_out = false
	sprite.speed_scale = 0.5
	sprite.play_backwards("dying")

func _on_sprite_2d_animation_finished():
	if sprite.animation == "soul_spawning":
		dying = false
		soul_out = true
		sprite.play("soul_idle")
		$Soul_respawn_time.start()
	
	if sprite.animation == "dying" and sprite.speed_scale == 0.5 and dying:
		sprite.speed_scale = 1
		current_vit = default_vit
		set_health_bar()
		dying = false
		set_idle()

func init_knockback(amount, force, sender):
	if not parring:
		super.init_knockback(amount, force, sender)

func _on_change_stats(stat, amount, time_duration, ally_sender):
	if not parring:
		super._on_change_stats(stat, amount, time_duration, ally_sender)
