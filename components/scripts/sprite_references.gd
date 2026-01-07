class_name SpriteReferences extends Node2D

@onready var up: Marker2D = %Up
@onready var right: Marker2D = %Right
@onready var down: Marker2D = %Down
@onready var left: Marker2D = %Left

var r : Dictionary[String, Marker2D]

func assign_values(up_pos : Vector2, right_pos : Vector2, down_pos : Vector2, left_pos : Vector2) -> void: 
	up.position = up_pos
	right.position = right_pos
	down.position = down_pos
	left.position = left_pos
	
	r["up"] = up
	r["right"] = right
	r["down"] = down
	r["left"] = left
	
	r.make_read_only()
