extends Node2D

@export var stations: Array[KitchenCauldron]
@export_range(1.0, 300.0) var walking_speed := 88.0
@export_range(0.1, 30.0) var stir_seconds := 4.5

@onready var sprite: AnimatedSprite2D = $Sprite

var station_index := 0
var time_left := 0.0
var approaching_station := false
var leaving_station := false


func _physics_process(delta: float) -> void:
	if stations.is_empty():
		return
	var cauldron := stations[station_index]
	if time_left > 0.0:
		time_left = maxf(0.0, time_left - delta)
		if time_left == 0.0:
			cauldron.set_stirring(false)
			sprite.show()
			leaving_station = true
		return

	var target := cauldron.station.global_position if approaching_station else cauldron.aisle.global_position
	var direction := target - global_position
	if absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0.0
	global_position = global_position.move_toward(target, walking_speed * delta)
	if not global_position.is_equal_approx(target):
		return
	if leaving_station:
		leaving_station = false
		station_index = (station_index + 1) % stations.size()
	elif approaching_station:
		approaching_station = false
		sprite.hide()
		cauldron.set_stirring(true)
		time_left = stir_seconds
	else:
		approaching_station = true
