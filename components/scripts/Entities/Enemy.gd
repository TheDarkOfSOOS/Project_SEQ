class_name Enemy extends Entity

var is_in_atk_range = false
var player

var target_position : Vector2

@onready var sprite : AnimatedSprite2D = $Sprite2D

@onready var healthbar : ProgressBar = $UI_container/HealthBar
@onready var status_container : HBoxContainer = $UI_container/Status_container
@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D

# override
func _on_change_stats(stat, amount, time_duration, ally_sender):
	if (is_in_atk_range and !grabbed) or time_duration == 0 or ally_sender:
		super._on_change_stats(stat, amount, time_duration, ally_sender)

func instantiate_status_icon(status : String, timer : Timer):
	var temp = super.instantiate_status_icon(status, timer)
	temp.reparent(status_container)
	#status_container.add_child(temp, true)

# override
func init_knockback(amount, force, sender):
	if is_in_atk_range and not grabbed:
		super.init_knockback(amount, force, sender)

func chase_player(flee : bool = false):
	if is_instance_valid(player) or flee:
		if not flee:
			navigation_agent.target_position = player.global_position
		
		target_position = navigation_agent.get_next_path_position()
		
		if navigation_agent.is_navigation_finished():
			if sprite.animation == "running":
				sprite.play("idle")
		else:
			self.velocity = global_position.direction_to(target_position) * current_des
			
			sprite.play("running")
			move_and_slide()
		
		if (target_position - self.global_position).x > 0:
			flip(true)
		else:
			flip(false)

func _on_player_is_in_atk_range(is_in, body):
	if is_in and body == self:
		is_in_atk_range = is_in
	else:
		is_in_atk_range = false

func _on_get_healed(amount):
	current_vit += amount
	show_hitmarker("+" + str(amount), false, hitmarker_spawnpoint)
	status_sprite.play("recover")
	self.set_health_bar()

#DIGEST DEL SEGNALE PROPRIO "set_health_bar", AGGIORNA LA BARRA DELLA SALUTE
	#il valore della barra diventa uguale a quello della vita attuale
	#se il valore della vita è minore o uguale a 0
		#cancello il nodo dalla scena

func set_health_bar():
	if current_vit <= 0:
		notify_death()
	elif current_vit > default_vit:
		current_vit = default_vit
	
	healthbar.value = current_vit

func notify_death():
	on_death_control()
	queue_free()




func on_death_control():
	if player.char_name == "Tyrone" and player.sprite.animation == "base atk5":
			QuestManager.quests["combo"].reach_goal_quest()
			QuestManager.quests["combo"].complete_quest()
