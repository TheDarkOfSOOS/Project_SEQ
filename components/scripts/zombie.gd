class_name Zombie extends Enemy

var scene_manager : Node2D

var grab_position

signal take_dmg(str, atk_str, sec_stun, pbc, efc, type, sender)
signal got_grabbed(is_grabbed)
signal shake_camera(shake, strenght)

var SPRITE_FLIP : bool
var BODY_COLLIDER_POSITION_X : float
var BODY_COLLIDER_ROTATION : float
var BITE_EFFECT_X : float
var BITE_EFFECT_FLIP : bool
var BITE_COLLIDER_POSITION_X : float

enum Possible_Attacks {IDLE, BITE, SPRINT}
var choosed_atk

var sprinting = false

@export var bite_force = 15
@export var bite_stun_time = 0.5
@onready var bite_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL

@export var sprint_force = 20
@export var sprint_stun_time = 0.3
@export var sprint_multiplyer = 150
@export var sprint_duration = 6.0
@onready var sprint_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL

@onready var bite_effect : AnimatedSprite2D = $Bite_Area/Effect
@onready var bite_collider : CollisionShape2D = $Bite_Area/Collider

@onready var body_collider : CollisionShape2D = $Body_collider

@onready var sprint_collider : CollisionShape2D = $Sprint_Area/Collider

@onready var sprint_charge_time : Timer = $Charge_Time
@onready var sprint_time : Timer = $Sprint_time

@onready var update_atk_timer : Timer = $Update_Atk

@onready var bite_cooldown : Timer = $Bite_Cooldown
@onready var sprint_cooldown : Timer = $Sprint_Cooldown

var player_in_atk_range = false

#METODO CHE PARTE QUANDO VIENE ISTANZIATO IL NODO
	#setta la vita attuale a quella massima
	#imposta il valore massimo della barra della salute al massimo
	#setta la barra della salute

func _ready():
	var stats : Stats = load("res://components/resources/stats/zombie_stats.tres")
	load_stats(stats)
	
	SPRITE_FLIP = sprite.flip_h
	BODY_COLLIDER_POSITION_X = body_collider.position.x
	BODY_COLLIDER_ROTATION = body_collider.rotation_degrees
	BITE_EFFECT_X = bite_effect.position.x
	BITE_EFFECT_FLIP = bite_effect.flip_h
	BITE_COLLIDER_POSITION_X = bite_collider.position.x
	
	sprites_to_flip = [
		sprite, SPRITE_FLIP,
		bite_effect, BITE_EFFECT_FLIP
	]
	
	nodes_to_flip = [
		bite_collider, BITE_COLLIDER_POSITION_X,
		bite_effect, BITE_EFFECT_X
	]
	
	nodes_to_flip_rotation = [
		body_collider, BODY_COLLIDER_POSITION_X
	]
	
	healthbar.max_value = default_vit
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
	if knockbacked:
		apply_knockback(delta)
	elif grabbed:
		pass
	elif sprinting:
		sprint_to_player()
	elif is_instance_valid(player) and moving:
		chase_player()
		if choosed_atk == Possible_Attacks.BITE and bite_cooldown.is_stopped():
			bite()
		if choosed_atk == Possible_Attacks.SPRINT and sprint_cooldown.is_stopped() and not sprinting and $Stun.is_stopped():
			sprint()
	elif not is_instance_valid(player) and not moving:
		set_idle()
	elif not is_instance_valid(player) and moving:
		sprite.play("idle")

func sprint_to_player():
	if is_instance_valid(player):
		var player_position = player.global_position
		if (player_position - self.global_position).normalized().x > 0:
			flip(true)
		else:
			flip(false)
		
		sprite.play("running")
		self.velocity = self.global_position.direction_to(player_position) * (current_des + sprint_multiplyer)
		move_and_slide()

func choose_atk():
	var rng = randi_range(0,100)
	if rng >= 0 and rng < 10:
		choosed_atk = Possible_Attacks.IDLE
	elif rng >= 10 and rng < 85:
		choosed_atk = Possible_Attacks.BITE
	else:
		choosed_atk = Possible_Attacks.SPRINT

	#choosed_atk = Possible_Attacks.SPRINT

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
		## print di debug #
		#impedisco al nodo di muoversi mentre viene attaccato
		#imposto il tempo di stun con il parametro passato
		#faccio partire il timer dello stun

func _on_player_take_dmg(atk_str, skill_str, stun_sec, atk_pbc, atk_efc, type, sender):
	if is_in_atk_range and !grabbed:
		var dmg_info = scene_manager.calculate_dmg(atk_str, skill_str, self.current_tem, atk_pbc, atk_efc, type, self)
		var dmg = dmg_info[0]
		show_hitmarker("-" + str(dmg), dmg_info[1], hitmarker_spawnpoint)
		current_vit -= dmg
		if dmg > 0:
			emit_hit_particles(sender)
			hit_flash_player.stop()
			hit_flash_player.play("hit_flash")
			emit_signal("shake_camera", true, dmg_info[2])
		set_health_bar()
		if sprinting and dmg >= 25:
			sprinting = false
			moving = false
			sprint_collider.set_deferred("disabled", true)
			sprite.play("damaged")
			stun_timer.wait_time = 0.1
			stun_timer.start()
		if stun_sec > 0:
			moving = false
			stun_timer.wait_time = stun_sec
			stun_timer.start()
			sprite.play("damaged")

# DIGEST DEL SENGALE DEL PLAYER "grab" #

func _on_player_grab(is_been_grabbed, _is_flipped, grab_position_marker):
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

#DIGEST DEL TIMER "Stun"
	#setto il movimento a true

func _on_stun_timeout():
	choosed_atk = Possible_Attacks.IDLE
	sprint_collider.set_deferred("disabled", true)
	set_idle()

# -------- SIGNAL DIGEST -------- #

#DIGEST CHE PERMETTE DI FAR RIPARTIRE IL MOVIMENTO

func set_idle():
	if not knockbacked and not grabbed:
		moving = true
		sprinting = false
		choosed_atk = Possible_Attacks.IDLE
		sprint_collider.set_deferred("disabled", true)
		sprint_charge_time.stop()
		sprite.play("idle")
		bite_effect.play("idle")

func _on_bite_area_body_entered(body):
	if body == player:
		player_in_atk_range = true

func _on_bite_area_body_exited(body):
	if body == player:
		player_in_atk_range = false

func _on_sprint_area_body_entered(body):
	if body == player:
		player_in_atk_range = true
		emit_signal("take_dmg", current_str, sprint_force, sprint_stun_time, current_pbc, current_efc, sprint_type, self)
		sprint_time.start(0.5)
		update_atk_timer.start(0.5)

func _on_sprint_area_body_exited(body):
	if body == player:
		player_in_atk_range = false

func _on_effect_animation_finished():
	if stun_timer.is_stopped() and bite_effect.animation == "effect" and not grabbed and player_in_atk_range:
		emit_signal("take_dmg",current_str, bite_force, bite_stun_time, current_pbc, current_efc, bite_type, self)
		bite_cooldown.start()
	set_idle()

func bite():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and player_in_atk_range and not sprinting:
		moving = false
		bite_effect.play("effect")
		sprite.play("attack")
	bite_cooldown.start()

func sprint():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed and not sprinting:
		moving = false
		sprite.play("charging_sprint")
		sprint_charge_time.start()
	sprint_cooldown.start()

func _on_sprint_time_timeout() -> void:
	set_idle()

func _on_charge_time_timeout():
	if stun_timer.is_stopped():
		sprinting = true
		sprint_collider.set_deferred("disabled", false)
		sprint_time.start(sprint_duration)

func _on_update_atk_timeout():
	if not sprinting:
		choose_atk()
	update_atk_timer.start()

func _on_knockback_reset():
	super._on_knockback_reset()
	if stun_timer.is_stopped():
		set_idle()
