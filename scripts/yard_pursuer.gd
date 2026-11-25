class_name YardPursuer
extends CharacterBody2D

@export var run_speed := 340.0
@export var reach := 35.0
@export var reaction_faces_left := false

@onready var art: AnimatedSprite2D = $Art
var target: CharacterBody2D
var entry_y := 0.0
var detour_side := 0.0
var facing_left := false
var returning_across_edge := false


func _ready() -> void:
	art.animation_finished.connect(_next_animation)


func begin(player: CharacterBody2D, ground_y := 0.0) -> void:
	target = player
	entry_y = ground_y
	detour_side = 0.0
	if reaction_faces_left:
		facing_left = true
		art.flip_h = false
	else:
		_face(target.global_position - global_position)
	art.play(&"startled")


func reset() -> void:
	target = null
	facing_left = reaction_faces_left
	art.flip_h = false
	if art.sprite_frames.has_animation(&"sleep"):
		art.play(&"sleep")
	else:
		art.stop()
		hide()


func advance(delta: float) -> bool:
	if target == null or art.animation != &"run":
		return false
	var direction := target.global_position - global_position
	var stride := run_speed * delta
	if global_position.y < entry_y:
		global_position.y = minf(global_position.y + stride, entry_y)
		return false
	if direction.length_squared() <= reach * reach:
		var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, collision_mask)
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			return true
	_move_toward(target.global_position, stride)
	return false


func begin_return() -> void:
	target = null
	detour_side = 0.0
	returning_across_edge = false
	if art.animation == &"run":
		art.play(&"run", 0.65)


func return_to(home: Vector2, ground_y: float, delta: float) -> bool:
	if global_position.distance_squared_to(home) <= 4.0:
		global_position = home
		reset()
		return true
	if art.animation != &"run":
		art.play(&"run", 0.65)
	var entry := Vector2(home.x, maxf(home.y, ground_y))
	var stride := run_speed * delta * 0.65
	var at_entry := absf(global_position.x - home.x) <= 2.0 and global_position.y <= ground_y + 2.0
	if home.y < ground_y and (at_entry or returning_across_edge):
		returning_across_edge = true
		global_position = global_position.move_toward(home, stride)
	else:
		returning_across_edge = false
		_move_toward(entry, stride)
	return false


func _move_toward(point: Vector2, stride: float) -> void:
	var from := global_position
	var direction := point - from
	var contact := move_and_collide(direction.limit_length(stride))
	if contact != null:
		var tangent := contact.get_normal().orthogonal()
		if detour_side == 0.0:
			detour_side = 1.0 if tangent.dot(direction) >= 0.0 else -1.0
		move_and_collide(tangent * detour_side * stride)
	else:
		detour_side = 0.0
	_face(global_position - from, false, 0.7)


func _next_animation() -> void:
	if target == null:
		return
	if art.animation == &"startled":
		_face(target.global_position - global_position, reaction_faces_left)
		art.play(&"angry")
	elif art.animation == &"angry":
		_face(target.global_position - global_position)
		art.play(&"run")


func _face(direction: Vector2, faces_left := false, threshold := 2.0) -> void:
	if absf(direction.x) > threshold:
		facing_left = direction.x < 0.0
	art.flip_h = facing_left != faces_left
