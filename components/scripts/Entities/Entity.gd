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

var moving : bool = true
var grabbed : bool = false

var knockback_controller_node : PackedScene = preload("res://scenes/miscellaneous/knockback_controller.tscn")
var knockbacked : bool = false
var knockback_target_point
var knockback_force

var sprite_references_scene : PackedScene = preload("res://scenes/miscellaneous/sprite_references.tscn")
var SPRITE_REFERENCES : SpriteReferences

var sprites_to_flip : Array
var nodes_to_flip : Array
var nodes_to_flip_rotation : Array

@onready var hit_flash_player : AnimationPlayer = $Hit_flash_player

@onready var hitmarker_spawnpoint = $Hitmarker_spawn

const hitmarker_scene : PackedScene = preload("res://scenes/miscellaneous/hitmarker.tscn")
const hit_particles_scene : PackedScene = preload("res://scenes/miscellaneous/hit_particles.tscn")
const status_icon : PackedScene = preload("res://scenes/miscellaneous/status_icon.tscn")

@onready var status_sprite : AnimatedSprite2D = $Status_alert_sprite
@onready var stun_timer : Timer = $Stun

@onready var game_manager : GameManager = get_tree().get_first_node_in_group("gm")

func load_stats(stats : Stats) -> void:
	default_vit = stats.vit
	#default_vit = 1
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
	
	if stats.up != Vector2.ZERO:
		SPRITE_REFERENCES = sprite_references_scene.instantiate()
		self.add_child(SPRITE_REFERENCES, true)
		SPRITE_REFERENCES.assign_values(stats.up, stats.right, stats.down, stats.left)

func flip(is_flipped):
	if is_flipped:
		for i in sprites_to_flip.size():
			if sprites_to_flip[i] is not bool:
				sprites_to_flip[i].flip_h = sprites_to_flip[i+1]
		
		for i in nodes_to_flip.size():
			if nodes_to_flip[i] is not float:
				nodes_to_flip[i].position.x = nodes_to_flip[i+1]
		
		for i in nodes_to_flip_rotation.size():
			if nodes_to_flip_rotation[i] is not float:
				nodes_to_flip_rotation[i].rotation_degrees = nodes_to_flip_rotation[i+1]
	else:
		for i in sprites_to_flip.size():
			if sprites_to_flip[i] is not bool:
				sprites_to_flip[i].flip_h = not sprites_to_flip[i+1]
		
		for i in nodes_to_flip.size():
			if nodes_to_flip[i] is not float:
				nodes_to_flip[i].position.x = -nodes_to_flip[i+1]
		
		for i in nodes_to_flip_rotation.size():
			if nodes_to_flip_rotation[i] is not float:
				nodes_to_flip_rotation[i].rotation_degrees = -nodes_to_flip_rotation[i+1]

func show_hitmarker(string : String, crit : bool, spawnpoint : Marker2D) -> void:
	# istanzio l'hitmarker 
	var hitmarker = hitmarker_scene.instantiate()
	# lo posiziono nello spawnpoint
	hitmarker.position = spawnpoint.global_position
	
	# creo il tween per lo spostamento casuale
	var tween = get_tree().create_tween()
	tween.tween_property(hitmarker, 
						"position", 
						spawnpoint.global_position + (Vector2(randf_range(-1,1), -randf()) * 40), 
						0.75)
	
	# cambio la label nella scena (che sono sicuro sia il child 0) con il danno
	hitmarker.get_child(0).text = string
	# se il danno è un crit
	if crit:
		# cambio il colore della label in oro
		hitmarker.get_child(0).set("theme_override_colors/font_color", Color.GOLDENROD)
	# aggiungo l'hitmarker alla scena
	if "+" in string:
		hitmarker.get_child(0).set("theme_override_colors/font_color", Color.LIME_GREEN)
	get_parent().add_child(hitmarker)

func _on_change_stats(stat : String, amount : int, time_duration : float, _ally_sender : bool) -> void:
	if "strenght" in stat:
		create_status_timer(stat, "str", amount, time_duration)
	elif "weakness" in stat:
		create_status_timer(stat, "str", -amount, time_duration)
	elif "vigor" in stat:
		create_status_timer(stat, "tem", amount, time_duration)
	elif "fragility" in stat:
		create_status_timer(stat, "tem", -amount, time_duration)
	elif "swiftness" in stat:
		create_status_timer(stat, "des", amount, time_duration)
	elif "slowdown" in stat:
		create_status_timer(stat, "des", -amount, time_duration)
	elif "luck" in stat:
		create_status_timer(stat, "pbc", amount, time_duration)
	elif "unluck" in stat:
		create_status_timer(stat, "pbc", -amount, time_duration)
	elif "gigi" in stat:
		create_status_timer(stat, "efc", amount, time_duration)
	elif "igig" in stat:
		create_status_timer(stat, "efc", -amount, time_duration)
	
	if "str" in stat:
		current_str += amount
	elif "tem" in stat:
		current_tem += amount
	elif "des" in stat:
		current_des += amount
	elif "pbc" in stat:
		current_pbc += amount
	elif "efc" in stat:
		current_efc += amount

func create_status_timer(status : String, stat : String, amount : int, time_duration : float) -> void:
	var calculated_amount
	if "str" in stat:
		calculated_amount = calculate_percentage(default_str, amount)
		current_str += calculated_amount
	elif "tem" in stat:
		calculated_amount = calculate_percentage(default_tem, amount)
		current_tem += calculated_amount
	elif "des" in stat:
		calculated_amount = calculate_percentage(default_des, amount)
		current_des += calculated_amount
	elif "pbc" in stat:
		calculated_amount = calculate_percentage(default_pbc, amount)
		current_pbc += calculated_amount
	elif "efc" in stat:
		calculated_amount = calculate_percentage(default_efc, amount)
		current_efc += calculated_amount
	
	if time_duration != 0:
		if amount > 0:
			status_sprite.play("buff")
		else:
			status_sprite.play("debuff")
		self.add_child(load("res://scenes/miscellaneous/time_of_change.tscn").instantiate(),true)
		var new_timer = get_child(-1)
		new_timer.stat = stat
		new_timer.amount = -calculated_amount
		new_timer.wait_time = time_duration
		new_timer.reset_stats.connect(self._on_change_stats)
		instantiate_status_icon(status, new_timer)
		new_timer.start()

func _on_status_alert_sprite_animation_finished():
	status_sprite.play("idle")

func instantiate_status_icon(status : String, timer : Timer) -> Variant:
	self.add_child(status_icon.instantiate(), true)
	var new_status_icon = get_child(-1)
	var image = get_tree().get_first_node_in_group("gm").Status_Icons[status]
	var texture = Image.load_from_file(image)

	new_status_icon.radial.texture_progress = ImageTexture.create_from_image(texture)
	
	new_status_icon.timer = timer
	return new_status_icon

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

func init_knockback(amount : int, force : int, sender : Vector2):
	velocity = Vector2(0, 0)
	moving = false
	knockbacked = true
	
	knockback_target_point = sender + (sender.direction_to(self.global_position) * amount)
	
	knockback_force = force
	
	var knockback_controller : KnockbackController = knockback_controller_node.instantiate()
	knockback_controller.target_point = knockback_target_point
	knockback_controller.vel_multiplyer = force
	knockback_controller.caller = self
	knockback_controller.target_reached.connect(self._on_knockback_reset)
	get_parent().call_deferred("add_child", knockback_controller, true)
	knockback_controller.global_position = self.global_position

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
