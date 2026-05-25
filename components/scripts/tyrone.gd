class_name Tyrone extends Player

var scene_manager : Node2D

enum Atk_States {IDLE, BASE_ATK, SK1, SK2, EVA, ULT}

signal is_in_atk_range(is_in, body)
signal take_dmg(str, atk_str, sec_stun, pbc, efc, type, sender)
signal set_health_bar(current_vit)
@warning_ignore("unused_signal")
signal get_healed(amount)
signal change_stats(stat, amount, time_duration, ally_sender)
signal inflict_knockback(amount, force, sender)
signal shake_camera(shake, strenght)

var initial_y_position = 0
const MAX_Y_POSITION = 270

var SPRITE_FLIP : bool
var SKILL1_EFFECT_FLIP : bool
var BASIC_ATK_COLLIDER_POSITION_X : float
var SKILL1_COLLIDER_POSITION_X : float

var atk_state = Atk_States.IDLE
var suitable_for_sliding : Array[Enemy]

var can_interact_with_something = false
var grab_marker
var grab_sender

var is_evading = false

var atk_anim_finished = true

var is_moving_ult = false
var ult_moving_mod

@export var basic_atk_force = 10
@export var basic_stun_time = 0.4
@onready var basic_atk_type = game_manager.Attack_Types.PHYSICAL

@export var evade_amount = 1000
@export var evade_force = 10
@export var evade_stun_time = 2.1
@onready var evade_type = game_manager.Attack_Types.PHYSICAL

@export var skill1_force = 12
@export var skill1_stun_time = 0.6
@onready var skill1_type = game_manager.Attack_Types.PHYSICAL

@export var skill2_force = 23
@export var skill2_stun_time = 1.4
@export var skill2_inflicted_status = "fragility"
@export var skill2_stat_amount = 30
@export var skill2_duration = 15
@export var skill2_knockback_amount = 300
@export var skill2_knockback_force = 7.2
@onready var skill2_type = game_manager.Attack_Types.PHYSICAL

@export var ult_force = 80
@export var ult_stun_time = 6
@export var ult_knockback_amount = 450
@export var ult_knockback_force = 8
@onready var ult_type = game_manager.Attack_Types.PHYSICAL

@onready var camera

@onready var bs_atk_collider : CollisionShape2D = $Basic_atk_Area/Atk_collider
@onready var sliding_collider : CollisionShape2D = $Sliding_area/Collider

@onready var skill1_collider : CollisionShape2D = $Skill_1_area/Skill_collider
@onready var skill1_effect : AnimatedSprite2D = $Skill_1_area/Effect

@onready var eva_collider : CollisionShape2D = $Eva_area/Eva_collider
@onready var eva_duration_timer : Timer = $Eva_area/Eva_time

@onready var skill2_collider : CollisionShape2D = $Skill2_area/Skill_collider
@onready var skill2_effect : AnimatedSprite2D = $Skill2_area/Effect

@onready var ult_collider : CollisionShape2D = $Ult_area/Ult_collider
@onready var ult_effect : AnimatedSprite2D = $Ult_area/Effect
@onready var ult_stop_timer : Timer = $Ult_area/Ult_time

@onready var skill1_cooldown : Timer = $Skill1_cooldown
@onready var skill2_cooldown : Timer = $Skill2_cooldown
@onready var eva_cooldown : Timer = $Eva_cooldown
@onready var ulti_cooldown : Timer = $Ulti_cooldown

@onready var body_collider : CollisionShape2D = $Body_collider

@onready var combo_time : Timer = $Combo_time

#METODO CHE VIENE CHIAMATO AD OGNI FRAME
	#se il player si può muovere
		#esegue il metodo per muoversi
	#esegue il metodo che gestisce gli attacchi
	#se sta eseguendo un\'evasione
		#esegue il metodo di evasione
	#se ha attivato la skill1
		#esegue il metodo di movimento della skill1

func _ready():
	var stats : Stats = load("res://components/resources/stats/tyrone_stats.tres")
	load_stats(stats)
	char_name = "Tyrone"
	
	SPRITE_FLIP = sprite.flip_h
	SKILL1_EFFECT_FLIP = skill1_effect.flip_h
	BASIC_ATK_COLLIDER_POSITION_X = bs_atk_collider.position.x
	SKILL1_COLLIDER_POSITION_X = skill1_collider.position.x
	
	EVADE_WAIT_TIME = 5.0
	SKILL1_WAIT_TIME = 8.0
	SKILL2_WAIT_TIME = 9.0
	ULTI_WAIT_TIME = 60.0
	
	eva_cooldown.wait_time = EVADE_WAIT_TIME
	skill1_cooldown.wait_time = SKILL1_WAIT_TIME
	skill2_cooldown.wait_time = SKILL2_WAIT_TIME
	ulti_cooldown.wait_time = ULTI_WAIT_TIME
	
	emit_signal("set_health_bar", default_vit)

func _physics_process(delta : float):
	if knockbacked:
		apply_knockback(delta)
	if grabbed:
		is_grabbed()
	if moving:
		move(delta)
	if stun_timer.is_stopped():
		atk_handler()
	if is_evading:
		evade()
	if is_moving_ult:
		ult_moving()

# OVERRIDE
func atk_handler():
	if Input.is_action_just_pressed("base_atk") and (sprite.animation == "idle" or sprite.animation == "running") and atk_anim_finished and not can_interact_with_something:
		moving = false
		bs_atk_collider.disabled = false
		atk_anim_finished = false
		atk_state = Atk_States.BASE_ATK
		sprite.play("base atk1")
		# gestione sliding 
		suitable_for_sliding.sort_custom(
			func(a, b): 
				return self.global_position.distance_to(a.global_position) <  self.global_position.distance_to(b.global_position)
		)
		if not suitable_for_sliding.is_empty():
			if (suitable_for_sliding[0].global_position.direction_to(self.global_position).x > 0):
				init_knockback(1, 20, suitable_for_sliding[0].SPRITE_REFERENCES.r["right"].global_position)
				flip_sprite(true)
			else:
				init_knockback(1, 20, suitable_for_sliding[0].SPRITE_REFERENCES.r["left"].global_position)
				flip_sprite(false)
		else:
			reset_axis()
	
	elif Input.is_action_just_pressed("base_atk") and sprite.animation == "base atk1" and atk_anim_finished and not can_interact_with_something:
		atk_state = Atk_States.BASE_ATK
		atk_anim_finished = false
		combo_time.stop()
		sprite.play("base atk2")
	
	elif Input.is_action_just_pressed("base_atk") and sprite.animation == "base atk2" and atk_anim_finished and not can_interact_with_something:
		atk_state = Atk_States.BASE_ATK
		atk_anim_finished = false
		combo_time.stop()
		sprite.play("base atk3")
	
	elif Input.is_action_just_pressed("base_atk") and sprite.animation == "base atk3" and atk_anim_finished and not can_interact_with_something:
		atk_state = Atk_States.BASE_ATK
		atk_anim_finished = false
		combo_time.stop()
		sprite.play("base atk4")
	
	elif Input.is_action_just_pressed("base_atk") and sprite.animation == "base atk4" and atk_anim_finished and not can_interact_with_something:
		atk_state = Atk_States.BASE_ATK
		atk_anim_finished = false
		combo_time.stop()
		sprite.play("base atk5")
	
	elif Input.is_action_just_pressed("skill1") and (sprite.animation == "idle" or sprite.animation == "running") and skill1_cooldown.is_stopped() and not can_interact_with_something:
		skill1_cooldown.start(SKILL1_WAIT_TIME)
		moving = false
		atk_state = Atk_States.SK1
		skill1_collider.disabled = false
		sprite.play("skill1")
		skill1_effect.play("effect")
		reset_axis()
	
	elif Input.is_action_just_pressed("evade") and (sprite.animation == "idle" or sprite.animation == "running") and eva_cooldown.is_stopped() and not can_interact_with_something:
		#if not knockbacked and stun_timer.is_stopped() and ult_stop_timer.is_stopped():
		# Controllo per la presenza del powerup "john"
		var temp = [EVADE_WAIT_TIME]
		temp = powerup_handler.apply_powerup_boost("John", temp)
		#print(temp)
		if temp == null:
			temp = 0
		
		eva_cooldown.start(EVADE_WAIT_TIME+temp)
		if temp != null:
			self.emit_signal("update_gui_cooldowns")
		eva_cooldown.start(EVADE_WAIT_TIME+temp)
		moving = false
		atk_state = Atk_States.EVA
		eva_duration_timer.start()
		sprite.play("eva")
		eva_collider.disabled = false
		is_evading = true
	
	elif Input.is_action_just_pressed("skill2") and (sprite.animation == "idle" or sprite.animation == "running") and skill2_cooldown.is_stopped() and not can_interact_with_something:
		skill2_cooldown.start(SKILL2_WAIT_TIME)
		moving = false
		atk_state = Atk_States.SK2
		sprite.play("skill2")
		skill2_effect.play("effect")
		reset_axis()

	elif Input.is_action_just_pressed("ult") and (sprite.animation == "idle" or sprite.animation == "running") and ulti_cooldown.is_stopped() and not can_interact_with_something:
		ulti_cooldown.start(ULTI_WAIT_TIME)
		moving = false
		atk_state = Atk_States.ULT
		sprite.play("charging_ult")
		ult_moving_mod = -9
		reset_axis()

	elif sprite.animation != "idle" or sprite.animation != "running":
		pass




# ----------------- AREA2D INIZIO ----------------- #
#DIGEST DELLE AREE2D PER GESTIRE QUANDO UN NEMICO ENTRA O ESCE DALL\'AREA
	#ogni metodo controlla sempre come prima cosa se il body è diverso da se stesso, altrimenti
	#manderebbe dei segnali inutili

func _on_basic_atk_area_body_entered(body):
	if body is Enemy:
		emit_signal("is_in_atk_range", true, body)

func _on_basic_atk_area_body_exited(body):
	if body != self:
		emit_signal("is_in_atk_range", false, body)

func _on_sliding_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		suitable_for_sliding.append(body)

func _on_sliding_area_body_exited(body: Node2D) -> void:
	if body is Enemy:
		var index = suitable_for_sliding.find(body)
		if index >= 0:
			suitable_for_sliding.remove_at(index)

func _on_eva_area_body_entered(body):
	if body != self:
		emit_signal("is_in_atk_range", true, body)
		emit_signal("take_dmg", current_str, evade_force, evade_stun_time, current_pbc, current_efc, evade_type, self)

func _on_eva_area_body_exited(body):
	if body != self:
		emit_signal("is_in_atk_range", false, body)

func _on_skill_1_area_body_entered(body):
	if body != self:
		emit_signal("is_in_atk_range", true, body)

func _on_skill_1_area_body_exited(body):
	if body != self:
		emit_signal("is_in_atk_range", false, body)

func _on_skill_2_area_body_entered(body):
	if body != self:
		emit_signal("is_in_atk_range", true, body)
		emit_signal("take_dmg", current_str, skill2_force, skill2_stun_time, current_pbc, current_efc, skill2_type, self)
		emit_signal("change_stats", skill2_inflicted_status, skill2_stat_amount, skill2_duration, false)
		
		var temp = [skill2_knockback_amount, skill2_knockback_force]
		temp = powerup_handler.apply_powerup_boost("Alvin", temp)
		#print(temp)
		if temp == null:
			temp = [0, 0]
		
		emit_signal("inflict_knockback", skill2_knockback_amount+temp[0], skill2_knockback_force+temp[1], self.global_position)
		#emit_signal("inflict_knockback", 10, 10, self.global_position)

func _on_skill_2_area_body_exited(body):
	if body != self:
		emit_signal("is_in_atk_range", false, body)

func _on_ult_area_body_entered(body):
	if body != self:
		emit_signal("is_in_atk_range", true, body)
		emit_signal("take_dmg", current_str, ult_force, ult_stun_time, current_pbc, current_efc, ult_type, self)
		dramatic_slow_motion(0.3, 1.0)
		
		var temp = [ult_knockback_amount, ult_knockback_force]
		temp = powerup_handler.apply_powerup_boost("Alvin", temp)
		if temp == null:
			temp = [0, 0]
		
		emit_signal("inflict_knockback", ult_knockback_amount+temp[0], ult_knockback_force+temp[1], self.global_position)

func _on_ult_area_body_exited(body):
	if body != self:
		emit_signal("is_in_atk_range", false, body)

# ----------------- AREA2D FINE ----------------- #



@warning_ignore("shadowed_variable_base_class")
func flip_sprite(flip):
	if flip:
		sprite.flip_h = true
		bs_atk_collider.position.x = -BASIC_ATK_COLLIDER_POSITION_X
		skill1_collider.position.x = -SKILL1_COLLIDER_POSITION_X
		skill1_effect.flip_h = true
	else:
		sprite.flip_h = false
		bs_atk_collider.position.x = BASIC_ATK_COLLIDER_POSITION_X
		skill1_collider.position.x = SKILL1_COLLIDER_POSITION_X
		skill1_effect.flip_h = false

func _on_sprite_2d_animation_finished():
	if atk_state == Atk_States.BASE_ATK and sprite.animation == "base atk1":
		atk_anim_finished = true
		combo_time.start()
	
	if atk_state == Atk_States.BASE_ATK and sprite.animation == "base atk2":
		atk_anim_finished = true
		combo_time.start()

	if atk_state == Atk_States.BASE_ATK and sprite.animation == "base atk3":
		atk_anim_finished = true
		combo_time.start()
	
	if atk_state == Atk_States.BASE_ATK and sprite.animation == "base atk4":
		atk_anim_finished = true
		combo_time.start()

	if atk_state == Atk_States.BASE_ATK and sprite.animation == "base atk5":
		set_idle()

	elif atk_state == Atk_States.ULT and sprite.animation == "charging_ult":
		sprite.play("ult_animation")

	elif atk_state == Atk_States.ULT and sprite.animation == "ult_animation":
		sprite.pause()
		ult_collider.disabled = false
		ult_effect.play("effect")

func _on_sprite_2d_frame_changed():
	if sprite.frame == 2 and sprite.animation == "base atk1":
		bs_atk_collider.set_deferred("disabled", true)
		bs_atk_collider.set_deferred("disabled", false)
		emit_signal("take_dmg", current_str, basic_atk_force, basic_stun_time, current_pbc, current_efc, basic_atk_type, self)
	
	elif sprite.frame == 2 and sprite.animation == "base atk2":
		bs_atk_collider.set_deferred("disabled", true)
		bs_atk_collider.set_deferred("disabled", false)
		emit_signal("take_dmg", current_str, basic_atk_force, basic_stun_time, current_pbc, current_efc, basic_atk_type, self)
	
	elif sprite.frame == 1 and sprite.animation == "base atk3":
		bs_atk_collider.set_deferred("disabled", true)
		bs_atk_collider.set_deferred("disabled", false)
		emit_signal("take_dmg", current_str, basic_atk_force, basic_stun_time, current_pbc, current_efc, basic_atk_type, self)
	
	elif sprite.frame == 1 and sprite.animation == "base atk4":
		bs_atk_collider.set_deferred("disabled", true)
		bs_atk_collider.set_deferred("disabled", false)
		emit_signal("take_dmg", current_str, basic_atk_force+1, basic_stun_time+0.1, current_pbc, current_efc, basic_atk_type, self)
	
	elif sprite.frame == 4 and sprite.animation == "base atk5":
		bs_atk_collider.set_deferred("disabled", true)
		bs_atk_collider.set_deferred("disabled", false)
		emit_signal("take_dmg", current_str, basic_atk_force+2, basic_stun_time+0.1, current_pbc, current_efc, basic_atk_type, self)
	
	if sprite.frame == 7 and sprite.animation == "ult_animation":
		sprite.pause()
		is_moving_ult = true
		initial_y_position = sprite.position.y

func _on_effect_frame_changed():
	if skill1_effect.frame % 2 == 0 and atk_state == Atk_States.SK1:
		skill1_collider.disabled = false
		await game_manager.force_delay(0.1)
		emit_signal("take_dmg", current_str, skill1_force, skill1_stun_time, current_pbc, current_efc, skill1_type, self)
		skill1_collider.disabled = true
	
	elif skill2_effect.frame == 2 and atk_state == Atk_States.SK2:
		skill2_collider.set_deferred("disabled", false)
	
	elif skill2_effect.frame == 3 and atk_state == Atk_States.SK2:
		skill2_collider.set_deferred("disabled", true)
	
	if ult_effect.frame == 5:
		ult_collider.set_deferred("disabled", true)

# METODO CHE FA MUOVERE LO SPRITE IN ALTO DURANTE L'ANIMAZIONE DELLA ULTI #
func ult_moving():
	self.set_collision_layer_value(1, false)
	self.set_collision_mask_value(2, false)
	sprite.z_index = 1
	sprite.position.y += ult_moving_mod
	if sprite.flip_h:
		sprite.position.x += -0.10
	else:
		sprite.position.x += 0.10
	if sprite.position.y == initial_y_position-MAX_Y_POSITION:
		sprite.frame += 1
		ult_moving_mod = 9
	if sprite.position.y == initial_y_position:
		is_moving_ult = false
		sprite.play()

#  -- set_idle mi permette di resettare il player allo stato di idle --  #
func set_idle():
	if not grabbed and not knockbacked:
		reset_axis()
		
		atk_state = Atk_States.IDLE
		
		self.rotation_degrees = 0
		sprite.z_index = 0
		sprite.flip_v = false
		
		stun_timer.stop()
		combo_time.stop()
		
		sprite.play("idle")
		skill1_effect.play("idle")
		skill2_effect.play("idle")
		ult_effect.play("idle")
		
		bs_atk_collider.set_deferred("disabled", true)
		skill1_collider.set_deferred("disabled", true)
		skill2_collider.set_deferred("disabled", true)
		eva_collider.set_deferred("disabled", true)
		ult_collider.set_deferred("disabled", true)
		
		body_collider.set_deferred("disabled", false)
		
		self.set_collision_layer_value(1, true)
		
		#self.set_collision_mask_value(2, true)
		self.set_collision_mask_value(3, true)
		
		moving = true
		is_evading = false
		is_moving_ult = false
		atk_anim_finished = true
		sprite.position = Vector2.ZERO

func _on_ult_time_timeout():
	set_idle()

  #-- quando finisce l\'effetto della skill allora disattivo l\'area e setto ad idle --  
func _on_effect_animation_finished():
	if atk_state == Atk_States.SK1:
		set_idle()

	elif atk_state == Atk_States.SK2:
		set_idle()

	elif atk_state == Atk_States.ULT:
		ult_stop_timer.start()

func _on_eva_time_timeout():
	set_idle()

func _on_combo_time_timeout():
	set_idle()

#METODO CHE GESTISCE L\'EVASIONE IN BASE ALLA DIREZIONE PREMUTA
func evade():
	velocity = Vector2.ZERO
	self.set_collision_layer_value(1, false)
	
	if axis != Vector2.ZERO:
		velocity += axis * evade_amount
	elif sprite.flip_h:
		velocity += Vector2(-1, 0) * evade_amount
	else:
		velocity += Vector2(1, 0) * evade_amount
	
	move_and_slide()

# -- DIGEST SEGNALI NEMICI -- 
func _on_enemy_take_dmg(atk_str, skill_str, stun_sec, atk_pbc, atk_efc, type, sender):
	var dmg_info = scene_manager.calculate_dmg(atk_str, skill_str, self.current_tem, atk_pbc, atk_efc, type, self)
	var dmg = dmg_info[0]
	show_hitmarker("-" + str(dmg), dmg_info[1], hitmarker_spawnpoint)
	current_vit -= dmg
	emit_signal("set_health_bar", current_vit)
	if dmg > 0:
		emit_hit_particles(sender)
		hit_flash_player.stop()
		hit_flash_player.play("hit_flash")
		emit_signal("shake_camera", true, dmg_info[2])
		if dmg >= (default_vit*30)/100:
			dramatic_slow_motion()
	if stun_sec > 0:
		set_idle()
		sprite.play("damaged")
		moving = false
		stun_timer.wait_time = stun_sec
		stun_timer.start()

func _on_enemy_grab(is_been_grabbed, grab_position_marker, sender):
	if is_been_grabbed and not grabbed:
		set_idle()
		sprite.play("damaged")
		moving = false
		grabbed = true
		
		self.set_collision_layer_value(1, false)
		self.set_collision_mask_value(2, false)
		
		grab_marker = grab_position_marker
		grab_sender = sender
		
		if not sender.sprite.flip_h:
			flip_sprite(true)
		else: 
			flip_sprite(false)
		
		if sprite.flip_h:
			sprite.flip_v = true 
			sprite.flip_h = false
		else:
			sprite.flip_v = false
		
	elif not is_been_grabbed:
		set_idle()
		grabbed = false

func is_grabbed():
	self.look_at(grab_sender.global_position)
	global_position = grab_marker.global_position

func _on_stun_timeout():
	set_idle()

func _on_knockback_reset():
	super._on_knockback_reset()
	combo_time.start()
