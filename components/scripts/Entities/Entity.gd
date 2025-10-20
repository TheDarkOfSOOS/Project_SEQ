class_name Entity extends CharacterBody2D

var default_vit : int
var current_vit : int = default_vit

var default_str : int
var current_str : int = default_str

var default_tem : int
var current_tem : int = default_tem

var default_des : int
var current_des : int = default_des

var default_pbc : int
var current_pbc : int = default_pbc

var default_efc : float
var current_efc : float = default_efc

var moving = true
var grabbed = false

var knockback_controller_node : PackedScene = preload("res://scenes/miscellaneous/knockback_controller.tscn")
var knockbacked = false
var knockback_target_point
var knockback_force

@onready var hit_flash_player = $Hit_flash_player

@onready var hitmarker_spawnpoint = $Hitmarker_spawn

const hitmarker_scene : PackedScene = preload("res://scenes/miscellaneous/hitmarker.tscn")
const hit_particles_scene : PackedScene = preload("res://scenes/miscellaneous/hit_particles.tscn")
@onready var status_sprite = $Status_alert_sprite
@onready var stun_timer = $Stun

func load_stats(stats : Resource):
	default_vit = stats.vit
	default_str = stats.str
	default_tem = stats.tem
	default_des = stats.des
	default_pbc = stats.pbc
	default_efc = stats.efc
	
	current_vit = default_vit
	current_str = default_str
	current_tem = default_tem
	current_des = default_des
	current_pbc = default_pbc
	current_efc = default_efc

func show_hitmarker(dmg, crit, hitmarker_spawnpoint):
	# istanzio l'hitmarker 
	var hitmarker = hitmarker_scene.instantiate()
	# lo posiziono nello spawnpoint
	hitmarker.position = hitmarker_spawnpoint.global_position
	
	# creo il tween per lo spostamento casuale
	var tween = get_tree().create_tween()
	tween.tween_property(hitmarker, 
						"position", 
						hitmarker_spawnpoint.global_position + (Vector2(randf_range(-1,1), -randf()) * 40), 
						0.75)
	
	# cambio la label nella scena (che sono sicuro sia il child 0) con il danno
	hitmarker.get_child(0).text = dmg
	# se il danno è un crit
	if crit:
		# cambio il colore della label in oro
		hitmarker.get_child(0).set("theme_override_colors/font_color", Color.GOLDENROD)
	# aggiungo l'hitmarker alla scena
	get_parent().add_child(hitmarker)

func _on_change_stats(stat, amount, time_duration, ally_sender):
	if "str" in stat:
		current_str += calculate_percentage(current_str, amount)
	elif "tem" in stat:
		current_tem += calculate_percentage(current_tem, amount)
	elif "des" in stat:
		current_des += calculate_percentage(current_des, amount)
	elif "pbc" in stat:
		current_pbc += calculate_percentage(current_pbc, amount)
	elif "efc" in stat:
		current_efc += calculate_percentage(current_efc, amount)
	
	if time_duration != 0:
		if amount > 0:
			status_sprite.play("buff")
		else:
			status_sprite.play("debuff")
		self.add_child(load("res://scenes/miscellaneous/time_of_change.tscn").instantiate(),true)
		var new_timer = get_child(get_child_count()-1)
		new_timer.stat = stat
		new_timer.amount = -amount
		new_timer.wait_time = time_duration
		new_timer.reset_stats.connect(self._on_change_stats)
		new_timer.start()

func _on_status_alert_sprite_animation_finished():
	status_sprite.play("idle")

func emit_hit_particles(attacker):
	# istanzio le particelle
	var particles : GPUParticles2D = hit_particles_scene.instantiate()
	# le posiziono sul punto di interesse (il target)
	particles.global_position = self.global_position
	# ricavo la direzione di dove indirizzarle
	var direction_of_spawning = attacker.global_position.direction_to(self.global_position)
	# metto la direzione ricavata nel process_material
	particles.process_material.direction = Vector3(direction_of_spawning.x, direction_of_spawning.y, 0)
	# aggiungo le particelle alla scena
	get_parent().add_child(particles)
	# le riproduco 
	particles.emitting = true

func init_knockback(amount, force, sender):
	velocity = Vector2(0, 0)
	moving = false
	knockbacked = true
	
	knockback_target_point = self.global_position + (sender.direction_to(self.global_position) * amount)
	knockback_force = force
	
	self.add_child(knockback_controller_node.instantiate(), true)
	var knockback_controller = get_child(-1)
	knockback_controller.reparent(get_parent())
	knockback_controller.target_point = knockback_target_point
	knockback_controller.vel_multiplyer = force
	knockback_controller.caller = self
	knockback_controller.target_reached.connect(self._on_knockback_reset)

func apply_knockback(delta):
	velocity = Vector2(0, 0)
	self.global_position = self.global_position.lerp(knockback_target_point, knockback_force * delta)
	move_and_slide()

func _on_knockback_reset():
	knockbacked = false

func calculate_percentage(base, perc):
	return (base * perc) / 100

func dramatic_slow_motion(time_reduction : float = 0.3, duration : float = 0.5):
	Engine.time_scale = time_reduction
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
