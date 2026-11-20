class_name LaundryConvoy
extends Node2D

signal phase_changed(phase: Phase)

enum Phase { LOADING, APPROACHING_HANDLES, PULLING_FULL, HIDDEN_BEHIND_BARRACK, RETURNING_EMPTY, POSITIONING }

@export var worker: AnimatedSprite2D
@export var guard: AnimatedSprite2D
@export var cart: LaundryCart
@export var route: Path2D
@export var pile: StealthCover
@export var building: Sprite2D

@export_range(1.0, 250.0) var travel_speed := 78.0
@export_range(1.0, 250.0) var pull_speed := 52.0
@export_range(1.0, 250.0) var worker_walk_speed := 93.0
@export_range(0.1, 30.0) var load_seconds := 6.0
@export_range(0.5, 2.0, 0.01) var worker_load_scale := 1.20
@export_range(0.1, 30.0) var hidden_seconds := 3.0
@export var fill_at_seconds := Vector3(1.5, 3.2, 5.0)
@export var guard_follow_from_x := 1100.0
@export var guard_offset_at_end := Vector2(-50, -10)
@export var guard_minimum_ground_y := 622.0
@export var worker_pull_grip := Vector2(15, -45)
@export var worker_push_grip := Vector2(20, -44)
@export var cart_clearance := 48.0
@export_range(0.0, 1.0) var behind_building_from := 0.71
@export_range(0.15, 1.0) var minimum_pile_scale := 0.90

var phase := Phase.LOADING
var elapsed := 0.0
var distance := 0.0
var _length := 0.0
var _start := Vector2.ZERO
var _worker_scale := Vector2.ONE
var _cart_start := Vector2.ZERO
var _guard_start := Vector2.ZERO
var _pile_scale := Vector2.ONE
var _maneuver := Curve2D.new()
var _maneuver_duration := 0.0
var _follow_distance := 0.0
var _follow_offset := Vector2.ZERO


func _ready() -> void:
	_start = worker.global_position
	_worker_scale = worker.scale
	_cart_start = cart.global_position
	_guard_start = guard.global_position
	_pile_scale = pile.get_node("Pijamas").scale
	_length = route.curve.get_baked_length()
	_follow_distance = _distance_at_white_line()
	_follow_offset = _guard_start - _cart_position_at(_follow_distance)
	_start_loading()


func _physics_process(delta: float) -> void:
	var remaining := delta
	while remaining > 0.000001:
		match phase:
			Phase.LOADING:
				var slice := minf(remaining, maxf(0.0, load_seconds - elapsed))
				elapsed += slice
				remaining -= slice
				_update_load()
				if elapsed >= load_seconds - 0.000001:
					_start_maneuver(false)
			Phase.PULLING_FULL, Phase.RETURNING_EMPTY:
				var returning := phase == Phase.RETURNING_EMPTY
				var speed := travel_speed if returning else pull_speed
				var left := distance if returning else _length - distance
				var slice := minf(remaining, left / speed)
				remaining -= slice
				distance = clampf(distance + (-1.0 if returning else 1.0) * slice * speed, 0.0, _length)
				_place_trip(returning)
				if left - slice * speed <= 0.000001:
					if returning:
						_start_maneuver(true)
					else:
						_start_hidden()
			Phase.HIDDEN_BEHIND_BARRACK:
				var slice := minf(remaining, maxf(0.0, hidden_seconds - elapsed))
				elapsed += slice
				remaining -= slice
				if elapsed >= hidden_seconds - 0.000001:
					_start_trip(true)
			Phase.APPROACHING_HANDLES, Phase.POSITIONING:
				var settling := phase == Phase.POSITIONING
				var slice := minf(remaining, maxf(0.0, _maneuver_duration - elapsed))
				elapsed += slice
				remaining -= slice
				var progress := clampf(elapsed / _maneuver_duration, 0.0, 1.0)
				worker.global_position = _maneuver.sample_baked(progress * _maneuver.get_baked_length(), true)
				if elapsed >= _maneuver_duration - 0.000001:
					if settling:
						_start_loading()
					else:
						_start_trip(false)


func look_direction() -> Vector2:
	var watched := worker.global_position if phase == Phase.LOADING else cart.global_position
	return (watched - guard.global_position).normalized()


func guard_is_exposed() -> bool:
	return guard.visible and guard.z_index >= building.z_index


func _start_loading() -> void:
	distance = 0.0
	worker.global_position = _start
	guard.global_position = _guard_start
	cart.global_position = _cart_start
	_set_depth(false)
	worker.scale = _worker_scale * worker_load_scale
	worker.flip_h = false
	worker.offset.x = 37.0
	worker.play(&"load_clothes")
	guard.flip_h = false
	guard.play(&"guard_idle_impatient")
	cart.set_load(LaundryCart.Load.EMPTY)
	pile.get_node("Pijamas").scale = _pile_scale
	_set_phase(Phase.LOADING)


func _update_load() -> void:
	var level := LaundryCart.Load.EMPTY
	var time := elapsed + 0.000001
	if time >= fill_at_seconds.z:
		level = LaundryCart.Load.FULL
	elif time >= fill_at_seconds.y:
		level = LaundryCart.Load.HALF
	elif time >= fill_at_seconds.x:
		level = LaundryCart.Load.SMALL
	if level != cart.load_level:
		cart.set_load(level)
	pile.get_node("Pijamas").scale = _pile_scale * lerpf(1.0, minimum_pile_scale, elapsed / load_seconds)


func _start_trip(returning: bool) -> void:
	worker.flip_h = true
	worker.offset.x = 0.0
	worker.play(&"push_cart" if returning else &"pull_back", 1.0 if returning else pull_speed / travel_speed)
	cart.set_load(LaundryCart.Load.EMPTY if returning else LaundryCart.Load.FULL, true)
	_place_trip(returning)
	_set_visible(true)
	_set_phase(Phase.RETURNING_EMPTY if returning else Phase.PULLING_FULL)


func _start_hidden() -> void:
	_set_visible(false)
	_set_phase(Phase.HIDDEN_BEHIND_BARRACK)


func _start_maneuver(settling: bool) -> void:
	worker.scale = _worker_scale
	var from := worker.global_position
	var destination := _start if settling else _worker_at_handles(false)
	var lane_y := maxf(_cart_start.y + cart_clearance, maxf(from.y, destination.y) + 25.0)
	_maneuver.clear_points()
	_maneuver.add_point(from)
	_maneuver.add_point(Vector2(from.x + (18.0 if settling else 0.0), lane_y),
		Vector2(18, -18) if settling else Vector2(-16, -18), Vector2(-25, 0) if settling else Vector2(25, 0))
	_maneuver.add_point(Vector2(destination.x, lane_y),
		Vector2(27, 0) if settling else Vector2(-27, 0), Vector2(0, -18))
	_maneuver.add_point(destination)
	_maneuver_duration = maxf(0.1, _maneuver.get_baked_length() / worker_walk_speed)
	worker.flip_h = settling
	worker.offset.x = 0.0
	worker.play(&"walk")
	if settling:
		cart.set_load(LaundryCart.Load.EMPTY)
	_set_phase(Phase.POSITIONING if settling else Phase.APPROACHING_HANDLES)


func _place_trip(returning: bool) -> void:
	cart.global_position = _cart_position_at(distance)
	worker.global_position = _worker_at_handles(returning)
	if distance > _follow_distance:
		var progress := inverse_lerp(_follow_distance, _length, distance)
		var offset := _follow_offset.lerp(guard_offset_at_end, smoothstep(0.0, 1.0, progress))
		guard.global_position = cart.global_position + offset
		guard.global_position.y = maxf(guard.global_position.y, guard_minimum_ground_y)
		guard.flip_h = returning
		guard.play(&"guard_walk", 1.0 if returning else pull_speed / travel_speed)
	else:
		guard.global_position = _guard_start
		guard.flip_h = false
		guard.play(&"guard_idle_impatient")
	_set_depth(_behind_building())


func _cart_position_at(offset: float) -> Vector2:
	var first := route.curve.get_point_position(0)
	var point := route.curve.sample_baked(offset, true)
	return _cart_start + route.to_global(point) - route.to_global(first)


func _distance_at_white_line() -> float:
	var first := route.curve.get_point_position(0)
	var previous := first
	var previous_x := _cart_start.x
	var offset := 0.0
	if previous_x >= guard_follow_from_x:
		return offset
	for point in route.curve.get_baked_points():
		var x := (_cart_start + route.to_global(point) - route.to_global(first)).x
		var span := previous.distance_to(point)
		if x >= guard_follow_from_x:
			return offset + span * inverse_lerp(previous_x, x, guard_follow_from_x)
		offset += span
		previous = point
		previous_x = x
	return _length


func _worker_at_handles(returning: bool) -> Vector2:
	var grip := worker_push_grip if returning else worker_pull_grip
	var mirrored := Vector2(-grip.x, grip.y) * worker.scale
	return cart.handles.global_position - mirrored


func _behind_building() -> bool:
	return distance > _length * behind_building_from


func _set_depth(behind: bool) -> void:
	var depth := building.z_index - 1 if behind else building.z_index
	cart.z_index = depth
	var worker_behind := behind or building.to_local(worker.global_position).x >= -48.0
	worker.z_index = building.z_index - 1 if worker_behind else building.z_index
	var guard_behind := building.to_local(guard.global_position).x >= -12.0
	guard.z_index = building.z_index - 1 if guard_behind else building.z_index


func _set_visible(shown: bool) -> void:
	worker.visible = shown
	guard.visible = shown or _follow_distance >= _length
	cart.visible = shown


func _set_phase(next: Phase) -> void:
	phase = next
	elapsed = 0.0
	phase_changed.emit(phase)
