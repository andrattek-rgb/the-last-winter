extends CharacterBody2D

@export var patrol_points := PackedVector2Array()
@export_range(1.0, 200.0) var walk_speed := 104.0
@export_range(0.5, 8.0) var sweep_seconds := 2.5

@onready var sprite: AnimatedSprite2D = $Sprite

var _next_point := 0
var _sweep_remaining := 0.0
var _blocked_time := 0.0


func _physics_process(delta: float) -> void:
	if patrol_points.is_empty():
		return
	if _sweep_remaining > 0.0:
		_sweep_remaining -= delta
		return

	var destination := patrol_points[_next_point]
	var to_destination := destination - position
	if to_destination.length() <= 2.0:
		velocity = Vector2.ZERO
		_sweep_remaining = sweep_seconds
		sprite.play(&"sweep")
		_advance()
		return

	if absf(to_destination.x) > 2.0:
		sprite.flip_h = to_destination.x < 0.0
	sprite.play(&"walk")
	velocity = to_destination.limit_length(walk_speed * delta) / delta
	move_and_slide()

	# A moved prop can block part of the saved route. Continue to the next stop.
	if get_position_delta().length_squared() < 0.01:
		_blocked_time += delta
		if _blocked_time >= 0.75:
			_advance()
	else:
		_blocked_time = 0.0


func _advance() -> void:
	_next_point = (_next_point + 1) % patrol_points.size()
	_blocked_time = 0.0
