class_name Player extends Entity

var char_name : String
@onready var powerup_handler

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
