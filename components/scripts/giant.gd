class_name Giant extends Enemy

var scene_manager : Node2D

var grab_position

var attacking = false

@export var punch_force = 25
@export var punch_stun_time = 2.0
@onready var punch_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL

@export var earthquake_force = 2.5
@onready var earthquake_type = get_tree().get_first_node_in_group("gm").Attack_Types.PHYSICAL

signal take_dmg(str, atk_str, sec_stun, pbc, efc, type, sender)
signal got_grabbed(is_grabbed)
signal shake_camera(shake, strenght)

var player_position

enum Possible_Attacks {IDLE, PUNCH, EARTHQUAKE}
var choosed_atk

var SPRITE_FLIP : bool
var SPRITE_POSITION : Vector2
var PUNCH_COLLIDER_POSITION_X : float
var PUNCH_EFFECT_POSITION_X : float
var PUNCH_EFFECT_FLIP : bool
var BODY_COLLIDER_POSITION_X : float
var BODY_COLLIDER_ROTATION : float

@onready var punch_collider : CollisionShape2D = $Punch_Area/Skill_collider
@onready var punch_effect : AnimatedSprite2D = $Punch_Area/Effect

@onready var earthquake_collider : CollisionShape2D = $Earthquake_Area/Skill_collider
@onready var earthquake_effect : AnimatedSprite2D = $Earthquake_Area/Effect

@onready var body_collider : CollisionShape2D = $Body_collider

@onready var punch_cooldown : Timer = $Punch_Cooldown
@onready var earthquake_cooldown : Timer = $Earthquake_Cooldown

@onready var update_atk_timer : Timer = $Update_Atk

var player_in_atk_range : bool = false

#METODO CHE PARTE QUANDO VIENE ISTANZIATO IL NODO
	#setta la vita attuale a quella massima
	#imposta il valore massimo della barra della salute al massimo
	#setta la barra della salute

func _ready():
	var stats : Resource = load("res://components/resources/stats/giant_stats.tres")
	load_stats(stats)
	
	SPRITE_POSITION = sprite.position
	
	SPRITE_FLIP = sprite.flip_h
	PUNCH_EFFECT_FLIP = punch_effect.flip_h
	
	PUNCH_COLLIDER_POSITION_X = punch_collider.position.x
	PUNCH_EFFECT_POSITION_X = punch_effect.position.x
	BODY_COLLIDER_POSITION_X = body_collider.position.x
	
	BODY_COLLIDER_ROTATION = body_collider.rotation_degrees
	
	sprites_to_flip = [
		sprite, SPRITE_FLIP,
		punch_effect, PUNCH_EFFECT_FLIP
	]
	
	nodes_to_flip = [ 
		punch_collider, PUNCH_COLLIDER_POSITION_X,
		punch_effect, PUNCH_EFFECT_POSITION_X,
		body_collider, BODY_COLLIDER_POSITION_X
	]
	
	nodes_to_flip_rotation = [
		body_collider, BODY_COLLIDER_ROTATION
	]
	
	healthbar.max_value = default_vit
	set_health_bar()
	sprite.play("idle")
	update_atk_timer.wait_time = randf_range(3, 5.8)

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
		is_grabbed()
	elif is_instance_valid(player) and moving and not attacking:
		chase_player()
		if choosed_atk == Possible_Attacks.PUNCH and punch_cooldown.is_stopped():
			punch()
		if choosed_atk == Possible_Attacks.EARTHQUAKE and earthquake_cooldown.is_stopped() and stun_timer.is_stopped():
			earthquake()
	elif not is_instance_valid(player) and not moving:
		set_idle()
	elif not is_instance_valid(player) and moving:
		sprite.play("idle")

#METODO CHE PERMETTE AL NODO DI SPOSTARSI VERSO IL PLAYER
	#salvo la posizione attuale del player
	#creo il vettore che punta al player, facendo la posizione del player - la posizione attuale e infine normalizzo il vettore
	#se il nodo è distante dal player di almeno 12 unità
		#muovo il nodo verso il player con la velocità di 3

func choose_atk():
	var rng = randi_range(0,100)
	if rng >= 0 and rng < 20:
		choosed_atk = Possible_Attacks.IDLE
	elif rng >= 20 and rng <= 80:
		choosed_atk = Possible_Attacks.PUNCH
	elif rng >= 80:
		choosed_atk = Possible_Attacks.EARTHQUAKE
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
		var dmg_info : Array = scene_manager.calculate_dmg(atk_str, skill_str, self.current_tem, atk_pbc, atk_efc, type, self)
		var dmg = dmg_info[0]
		show_hitmarker("-" + str(dmg), dmg_info[1], hitmarker_spawnpoint)
		current_vit -= dmg
		set_health_bar()
		if dmg > 0:
			emit_hit_particles(sender)
			hit_flash_player.stop()
			hit_flash_player.play("hit_flash")
			emit_signal("shake_camera", true, dmg_info[2])
		if (dmg >= 25 or dmg <= 0) and stun_sec > 0:
			punch_effect.play("idle")
			attacking = false
			moving = false
			stun_timer.start(stun_sec)
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
		healthbar.visible = true
		
		if player.char_name == "Nathan":
			emit_signal("got_grabbed", false)
			sprite.rotation_degrees = 0;
			healthbar.visible = true

# METODO CHE TELETRASPORTA IL NODO NELLA POSIZIONE DEL PLAYER DURANTE LA GRAB #

func is_grabbed():
	flip((player.position - position).normalized())
	position = grab_position.global_position

#DIGEST DEL TIMER "Stun"
	#setto il movimento a true

func _on_stun_timeout():
	choosed_atk = Possible_Attacks.IDLE
	set_idle()

func _on_punch_area_body_entered(body):
	if body == player:
		player_in_atk_range = true

func _on_punch_area_body_exited(body):
	if body == player:
		player_in_atk_range = false

func _on_earthquake_area_body_entered(body):
	if body == player:
		player_in_atk_range = true

func _on_earthquake_area_body_exited(body):
	if body == player:
		player_in_atk_range = false
		player.current_des = player.default_des
# -------- SIGNAL DIGEST -------- #

func _on_sprite_2d_animation_finished():
	if sprite.animation == "punch":
		set_idle()

func _on_sprite_2d_frame_changed():
	if (sprite.animation == "earthquake" and sprite.frame == 1) or (sprite.animation == "earthquake" and sprite.frame == 3) or (sprite.animation == "earthquake" and sprite.frame == 7):
		if earthquake_effect.is_playing():
			earthquake_effect.stop()
			earthquake_effect.play("effect")
		else:
			earthquake_effect.play("effect")
	if sprite.animation == "punch" and sprite.frame == 8 and stun_timer.is_stopped() and not grabbed and player_in_atk_range:
		emit_signal("take_dmg", current_str, punch_force, punch_stun_time, current_pbc, current_efc, punch_type, self)

# FUNZIONE PER L'ATTACCO PUGNO
func punch():
	if stun_timer.is_stopped() and not grabbed:
		punch_cooldown.start()
		attacking = true
		if sprite.flip_h:
			sprite.position.x += -58
		else:
			sprite.position.x += 58
		moving = false
		sprite.play("punch")
		punch_effect.play("effect")
		punch_collider.set_deferred("disabled", false)

func _on_effect_animation_finished():
	if punch_effect.animation == "effect":
		punch_effect.play("idle")
	if earthquake_effect.animation == "effect":
		set_idle()

func _on_effect_frame_changed():
	if earthquake_effect.animation == "effect" and earthquake_effect.frame%2==0 and stun_timer.is_stopped() and not grabbed and player_in_atk_range:
		emit_signal("take_dmg", current_str, earthquake_force, 0, 0, 0, earthquake_type, self)
		emit_signal("shake_camera", true, 60)
		if player.current_des == player.default_des:
			player.current_des /= 2.5
			player.status_sprite.play("debuff")

# FUNZIONE PER L'ATTACCO TERREMOTO'
func earthquake():
	if is_instance_valid(player) and stun_timer.is_stopped() and not grabbed:
		earthquake_cooldown.start()
		attacking = true
		moving = false
		sprite.play("earthquake")
		earthquake_collider.set_deferred("disabled", false)

# DIGEST CHE PERMETTE DI FAR RIPARTIRE IL MOVIMENTO
func set_idle():
	if not knockbacked and not grabbed:
		sprite.position = SPRITE_POSITION
		moving = true
		attacking = false
		punch_collider.set_deferred("disabled", true)
		earthquake_collider.set_deferred("disabled", true)
		sprite.play("idle")
		punch_effect.play("idle")
		earthquake_effect.play("idle")

func _on_update_atk_timeout():
	choose_atk()
	update_atk_timer.wait_time = randf_range(3, 5.8)
	update_atk_timer.start()

func _on_knockback_reset():
	super._on_knockback_reset()
	if stun_timer.is_stopped():
		set_idle()
