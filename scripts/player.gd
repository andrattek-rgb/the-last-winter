extends CharacterBody2D

@export_range(1.0, 600.0) var horizontal_speed := 260.0
@export_range(1.0, 600.0) var depth_speed := 165.0
@export var crouch_enabled := false
@export_range(0.1, 1.0) var crouch_speed_factor := 0.43

@onready var sprite: AnimatedSprite2D = $Sprite

var crouched := false


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_back", &"move_forward")
	crouched = crouch_enabled and Input.is_action_pressed(&"crouch")
	var speed_factor := crouch_speed_factor if crouched else 1.0
	velocity = direction * Vector2(horizontal_speed, depth_speed) * speed_factor
	move_and_slide()
	if not is_zero_approx(direction.x):
		sprite.flip_h = direction.x < 0.0
	var moving := get_real_velocity().length_squared() > 1.0
	if crouched:
		sprite.play(&"crouch_walk" if moving else &"crouch_idle")
	else:
		sprite.play(&"run" if moving else &"idle")
