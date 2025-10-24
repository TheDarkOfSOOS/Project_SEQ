extends NinePatchRect

@onready var radial : TextureProgressBar = $RadialBar
var timer : Timer

func _process(_delta: float) -> void:
	if is_instance_valid(timer) and not timer.is_stopped():
		radial.max_value = timer.wait_time
		radial.value = timer.time_left
	else:
		queue_free()
