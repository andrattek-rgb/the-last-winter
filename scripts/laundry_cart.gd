class_name LaundryCart
extends Node2D

enum Load { EMPTY, SMALL, HALF, FULL }

@export_range(0.1, 2.0) var wheel_speed_factor := 0.70

@onready var cover: StealthCover = $Cobertura
@onready var art: Node2D = $Arte
@onready var handles: Marker2D = $Arte/Pegas
@onready var wheels: AnimatedSprite2D = $Arte/Rodas
@onready var small_load: Sprite2D = $Arte/PoucaRoupa
@onready var half_load: Sprite2D = $Arte/MeioCheio

var load_level := Load.EMPTY


func set_load(level: Load, rolling := false) -> void:
	load_level = level
	small_load.visible = level == Load.SMALL
	half_load.visible = level == Load.HALF
	wheels.visible = level == Load.EMPTY or level == Load.FULL
	var animation := &"full_roll" if level == Load.FULL else &"empty_roll"
	if rolling:
		wheels.play(animation, wheel_speed_factor if level == Load.FULL else 1.0)
	else:
		wheels.stop()
		wheels.animation = animation
		wheels.frame = 0
