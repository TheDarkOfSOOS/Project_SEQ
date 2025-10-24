class_name Enemy extends Entity

var is_in_atk_range = false
var player

@onready var healthbar = $UI_container/HealthBar
@onready var status_container = $UI_container/Status_container

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

func _on_player_is_in_atk_range(is_in, body):
	if is_in and body == self:
		is_in_atk_range = is_in
	else:
		is_in_atk_range = false

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
