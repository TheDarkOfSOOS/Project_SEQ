class_name Enemy extends Entity

var is_in_atk_range = false
var player

# override
func _on_change_stats(stat, amount, time_duration, ally_sender):
	if (is_in_atk_range and !grabbed) or time_duration == 0 or ally_sender:
		super._on_change_stats(stat, amount, time_duration, ally_sender)

# override
func init_knockback(amount, force, sender):
	if is_in_atk_range and not grabbed:
		super.init_knockback(amount, force, sender)

func _on_player_is_in_atk_range(is_in, body):
	if is_in and body == self:
		is_in_atk_range = is_in
	else:
		is_in_atk_range = false
