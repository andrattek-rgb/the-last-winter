extends CharacterBody2D

@export_range(1.0, 600.0) var horizontal_speed := 260.0
@export_range(1.0, 600.0) var depth_speed := 165.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	velocity = direction * Vector2(horizontal_speed, depth_speed)
	move_and_slide()
