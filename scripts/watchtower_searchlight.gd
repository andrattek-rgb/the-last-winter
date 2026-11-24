extends Node2D

@export var emitter: Marker2D
@export var shadow_origin: Marker2D
@export var safe_boundary: Marker2D
@export var sweep_points: Array[Marker2D]
@export var crate_footprints: Array[CollisionShape2D]
@export var spot_radius := Vector2(266, 205)
@export_range(30.0, 900.0) var sweep_speed := 540.0
@export_range(0.0, 5.0, 0.05) var box_pause_seconds := 1.0
@export_range(0.05, 3.0) var detection_seconds := 0.32
@export var player: CharacterBody2D
@export var spawn: Marker2D
@export var camera: Camera2D
@export var caught_notice: Label

@onready var spot: ColorRect = $CirculoNoChao
@onready var beam: Polygon2D = $Feixe
@onready var lamp_glow: Sprite2D = $BrilhoDaLampada
@onready var spot_material: ShaderMaterial = spot.material

var destination := 1
var sweep_direction := 1
var spot_center := Vector2.ZERO
var hold_remaining := 0.0
var exposure := 0.0
var caught := false
var footprints: Array[Rect2] = []


func _ready() -> void:
	var shader_rects := PackedVector4Array()
	for footprint in crate_footprints:
		var shape := footprint.shape as RectangleShape2D
		var bounds: Rect2 = footprint.global_transform * Rect2(-shape.size * 0.5, shape.size)
		footprints.append(bounds)
		shader_rects.append(Vector4(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y))
	shader_rects.resize(4)
	spot_material.set_shader_parameter("cover_rects", shader_rects)
	spot_material.set_shader_parameter("safe_x", safe_boundary.global_position.x)
	spot_material.set_shader_parameter("shadow_origin", shadow_origin.global_position)
	spot_material.set_shader_parameter("spot_radius", spot_radius)
	spot_center = sweep_points[0].global_position
	hold_remaining = box_pause_seconds
	lamp_glow.global_position = emitter.global_position
	lamp_glow.show()
	_update_visuals()
	beam.polygons = [PackedInt32Array([0, 1, 2, 5]), PackedInt32Array([5, 2, 3, 4])]


func _physics_process(delta: float) -> void:
	var previous_center := spot_center
	_advance_sweep(delta)
	if spot_center != previous_center:
		_update_visuals()
	if caught:
		return
	if catches_at(player.global_position):
		exposure += delta
		if exposure >= detection_seconds:
			_restart()
	else:
		exposure = 0.0


func catches_at(point: Vector2) -> bool:
	return (
		point.x >= safe_boundary.global_position.x
		and ((point - spot_center) / spot_radius).length_squared() <= 1.0
		and not is_in_shadow(point)
	)


func is_in_shadow(point: Vector2) -> bool:
	var origin := shadow_origin.global_position
	for bounds in footprints:
		if bounds.has_point(point):
			return true
		var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y),
			bounds.end, Vector2(bounds.position.x, bounds.end.y)]
		for i in corners.size():
			if Geometry2D.segment_intersects_segment(origin, point, corners[i], corners[(i + 1) % 4]) != null:
				return true
	return false


func _advance_sweep(delta: float) -> void:
	var travel_time := delta - hold_remaining
	hold_remaining = maxf(0.0, hold_remaining - delta)
	if travel_time <= 0.000001:
		return
	var last := sweep_points.size() - 1
	var goal := sweep_points[destination].global_position
	spot_center = spot_center.move_toward(goal, sweep_speed * travel_time)
	if spot_center == goal:
		hold_remaining = box_pause_seconds
		if destination == 0 or destination == last:
			sweep_direction = -sweep_direction
		destination += sweep_direction


func _update_visuals() -> void:
	spot.global_position = spot_center - spot_radius
	spot.size = spot_radius * 2.0
	spot_material.set_shader_parameter("spot_center", spot_center)
	var source := to_local(emitter.global_position)
	var target := to_local(spot_center)
	var side := (target - source).normalized().orthogonal()
	beam.polygon = PackedVector2Array([source - side * 22.0, target - side * 156.0, target,
		target + side * 156.0, source + side * 22.0, source])


func _restart() -> void:
	caught = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	player.get_node("Sprite").play(&"idle")
	caught_notice.show()
	await get_tree().create_timer(0.8).timeout
	player.global_position = spawn.global_position
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()
	exposure = 0.0
	caught_notice.hide()
	player.set_physics_process(true)
	caught = false
