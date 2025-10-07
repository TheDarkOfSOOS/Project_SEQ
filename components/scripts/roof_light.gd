extends Sprite2D

#@onready var light : PointLight2D = $Light
#@onready var area : Area2D = $Area2D
#@onready var collider : CollisionShape2D = $Area2D/Collider

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.find_children("*", "LightOccluder2D"):
		var occluder : Array[Node] = body.find_children("*", "LightOccluder2D")
		for i in occluder:
			if i.is_visible():
				i.set_visible(false)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.find_children("*", "LightOccluder2D"):
		var occluder : Array[Node] = body.find_children("*", "LightOccluder2D")
		for i in occluder:
			if not i.is_visible():
				i.set_visible(true)
