extends Control

var round_count = 0
@onready var round_displayer = $MarginContainer/PanelContainer/Round_displayer

@onready var healthbar = $Boss_GUI/Health_bar
@onready var healthbar_label = $Boss_GUI/Health_bar/Health_label

@onready var animation_player = $AnimationPlayer

signal powerup_spawnable()

var max_health

var spawned_boss
# ogni quante ondate spawna un powerup
#var powerup_round : int = 1
var powerup_round : int = 5

@onready var game_manager : GameManager = get_tree().get_first_node_in_group("gm")

func _ready():
	round_displayer.text = "Ondata: " + str(round_count)

func _on_round_changed():
	round_count += 1
	if round_count == 6 and QuestManager.quests["try"].status == QuestStatus.of_type.started:
		QuestManager.quests["try"].reach_goal_quest()
		QuestManager.quests["try"].complete_quest()
	# FREQUENZA DI SPAWN DEI POWERUPS
	if round_count % powerup_round == 0:
		emit_signal("powerup_spawnable")
	round_displayer.text = "Ondata: " + str(round_count)

func _on_boss_set_healthbar(vit):
	if vit <= 0:
		if get_parent().get_parent().player.char_name == "Nathan":
			emit_signal("got_grabbed", false)
		spawned_boss.set_idle()
		spawned_boss.dying = true
		spawned_boss.update_atk_timer.stop()
		spawned_boss.set_idle_timer.stop()
		spawned_boss.stun_timer.stop()
		dramatic_slow_motion(0.15, 3)
		animation_player.play("delete_boss_bar")
		spawned_boss.sprite.reparent(spawned_boss.get_parent())
		if QuestManager.quests["the_bigger_they_are"].status == QuestStatus.of_type.started:
			QuestManager.quests["the_bigger_they_are"].reach_goal_quest()
	if vit > max_health:
			vit = max_health
	healthbar.value = vit
	healthbar_label.text = spawned_boss.boss_name + ": " + str(vit) + "/" + str(max_health)

func _on_boss_spawned(boss):
	animation_player.play("spawn_boss_bar")
	self.spawned_boss = boss
	max_health = boss.default_vit
	healthbar_label.text = boss.boss_name + ": " + str(boss.current_vit) + "/" + str(max_health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "spawn_boss_bar":
		healthbar.max_value = max_health
		healthbar.value = spawned_boss.current_vit
	if anim_name == "delete_boss_bar":
		spawned_boss = null
		healthbar.max_value = 100

func dramatic_slow_motion(time_reduction : float = 0.3, duration : float = 0.5) -> void:
	Engine.time_scale = time_reduction
	await game_manager.force_delay(duration)
	#await get_tree().create_timer(duration, false, false, true).timeout
	Engine.time_scale = 1.0
	
