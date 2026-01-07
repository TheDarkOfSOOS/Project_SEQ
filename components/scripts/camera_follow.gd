class_name CameraFollower extends CharacterBody2D

var player : CharacterBody2D
@onready var camera : Camera2D = $Main_camera
@export var weight : float = 3.4

func _ready() -> void:
	if is_instance_valid(player):
		player.camera = self.camera
		player.shake_camera.connect(self.camera._on_player_shake_camera)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(player):
		var distance = self.global_position.distance_to(player.global_position)
		
		if distance > 600:
			toggle_collision(false)
		
		if distance < 1:
			toggle_collision(true)
	
		self.global_position = self.global_position.lerp(player.global_position, delta * weight)
	move_and_slide()

func toggle_collision(activate : bool):
	if activate:
		$CollisionShape2D.disabled = false
	else:
		$CollisionShape2D.disabled = true
