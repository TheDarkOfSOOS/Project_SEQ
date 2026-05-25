class_name Player extends Entity

var char_name : String
@onready var powerup_handler

@onready var axis : Vector2 = Vector2.ZERO
var ACCELERATION : float = 10000.0
var FRICTION : float = 6500.0

@onready var sprite : AnimatedSprite2D = $Sprite2D
var sprite_animation_speed : float = 1.0

var EVADE_WAIT_TIME
var SKILL2_WAIT_TIME
var SKILL1_WAIT_TIME
#var ULTI_WAIT_TIME
var ULTI_WAIT_TIME
var ULTI_DURATION

signal update_gui_cooldowns()

#METODO CHE GESTISCE IL MOVIMENTO DEL PLAYER
	#pulisce il vettore della velocità
	## Last Win #
	#quando si gira il player a destra o sinistra si deve girare anche le aree, 
	#altrimenti ci sarebbe il personaggio flippato ma l\'area rimane dall\'altra
	#parte

func move(delta : float) -> void:
	axis = get_input_axis()
	
	if axis == Vector2.ZERO:
		apply_friction(FRICTION * delta)
	else:
		sprite.play("running")
		apply_movement(axis * ACCELERATION * delta)
		if axis.x < 0:
			flip_sprite(true)
		elif axis.x > 0:
			flip_sprite(false)
		
	move_and_slide()

# METODO CHE PRENDE GLI ASSI PER IL MOVIMENTO
func get_input_axis() -> Vector2:
	axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return axis

# METODO CHE APPLICA L'ATTRITO
func apply_friction(amount : float) -> void:
	if velocity.length() > amount:
		velocity -= velocity.normalized() * amount
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

# METODO CHE APPLICA IL MOVIMENTO CON L'ACCELERAZIONE
func apply_movement(accel : Vector2) -> void:
	velocity += accel
	velocity = velocity.limit_length(current_des * 2.5)

# METODO PER RESETTARE GLI ASSI DEL MOVIMENTO
func reset_axis() -> void:
	velocity = Vector2.ZERO
	axis = Vector2.ZERO

#METODO CHE GESTISCE TUTTE LE ABILITA' DEL PLAYER
	#ad ogni if si controlla l'azione possibile, per l'attacco di base si trovano
	#dei controlli aggiuntivi in base alla combo:
	#si controlla come prima cosa se l'input è stato premuto, se l'animazione è diversa da idle o running (ovvero o è fermo
	#o si sta spostando) oppure il numero di combo che sta facendo ed infine se non è in cooldown

func atk_handler() -> void:
	pass

# TODO - DEPRECATO -
func flip_sprite(_flip) -> void:
	pass

func init_knockback(amount, force, sender):
	if not grabbed:
		super.init_knockback(amount, force, sender)

func _on_get_healed(amount):
	var temp = powerup_handler.apply_powerup_boost("Abigail", [amount])
	if temp != null:
		amount += temp
	current_vit += amount
	show_hitmarker("+" + str(amount), false, hitmarker_spawnpoint)
	if current_vit > default_vit:
		current_vit = default_vit
	status_sprite.play("recover")
	emit_signal("set_health_bar", current_vit)
