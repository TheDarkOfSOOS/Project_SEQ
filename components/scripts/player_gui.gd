class_name Player_GUI extends Control

var player : Player

@onready var skill1_progress_bar : TextureProgressBar = %Skill1_cooldown
@onready var skill2_progress_bar : TextureProgressBar = $%Skill2_cooldown
@onready var eva_progress_bar : TextureProgressBar = %Eva_cooldown
@onready var ulti_progress_bar : TextureProgressBar = %Ulti_cooldown

@onready var healthbar : TextureProgressBar = %Health_bar
@onready var healthbar_label = %Health_label

var animation_player : AnimationPlayer
var max_health : int

signal player_death()

var alive = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_node_or_null("AnimationPlayer"):
		animation_player = $AnimationPlayer
	healthbar.max_value = max_health
	healthbar.value = player.current_vit
	healthbar_label.text = str(player.default_vit) + "/" + str(player.default_vit)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player != null and not alive:
		skill1_progress_bar.max_value = player.SKILL1_WAIT_TIME
		skill2_progress_bar.max_value = player.SKILL2_WAIT_TIME
		eva_progress_bar.max_value = player.EVADE_WAIT_TIME
		ulti_progress_bar.max_value = player.ULTI_WAIT_TIME
		alive = true
	
	if player != null:
		skill1_progress_bar.value = player.skill1_cooldown.time_left
		skill2_progress_bar.value = player.skill2_cooldown.time_left
		eva_progress_bar.value = player.eva_cooldown.time_left
		ulti_progress_bar.value = player.ulti_cooldown.time_left
		
	if not is_instance_valid(player) and alive:
		alive = false
		emit_signal("player_death")

func _on_player_set_health_bar(vit : int):
	if vit <= 0:
		player.queue_free()
	
	if player.default_vit != healthbar.max_value:
		healthbar.max_value = player.default_vit
	
	healthbar.value = vit
	healthbar_label.text = str(vit) + "/" + str(player.default_vit)

# METODO PER AGGIORNARE I COOLDOWNS NEL CASO DI POWERUPS CHE LO FANNO
func _on_update_cooldowns() -> void:
	skill1_progress_bar.max_value = player.SKILL1_WAIT_TIME
	skill2_progress_bar.max_value = player.SKILL2_WAIT_TIME
	eva_progress_bar.max_value = player.EVADE_WAIT_TIME
	ulti_progress_bar.max_value = player.ULTI_WAIT_TIME

# DEPRECATED
func _on_nathan_grab(is_grabbed):
	if is_grabbed:
		player.skill2_cooldown.stop()
		skill2_progress_bar.tint_under = Color(Color.RED,1)
		player._on_get_healed(player.bite_heal_force)
	else:
		player.skill2_cooldown.start()
		skill2_progress_bar.tint_under = Color(Color.WHITE,1)

# METODO DI JACK PER FAR PARTIRE L'EFFETTO DELLA FLASHBANG
func _on_jack_flashbang():
	animation_player.play("flashbang")
