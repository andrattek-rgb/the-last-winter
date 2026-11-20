class_name LaundryCart
extends Node2D

enum Load { EMPTY, SMALL, HALF, FULL }

@export_range(0.1, 2.0) var wheel_speed_factor := 0.70
@export_range(0.1, 0.9, 0.01) var fill_transition_seconds := 0.48

@onready var cover: StealthCover = $Cobertura
@onready var art: Node2D = $Arte
@onready var handles: Marker2D = $Arte/Pegas
@onready var wheels: AnimatedSprite2D = $Arte/Rodas
@onready var small_load: Sprite2D = $Arte/PoucaRoupa
@onready var half_load: Sprite2D = $Arte/MeioCheio

var load_level := Load.EMPTY
var _fill_tween: Tween


func set_load(level: Load, rolling := false, animate_fill := false) -> void:
	var previous := _load_art(load_level)
	var next := _load_art(level)
	if _fill_tween != null:
		_fill_tween.kill()
		_fill_tween = null
	load_level = level
	for sprite: Node2D in [wheels, small_load, half_load]:
		sprite.modulate.a = 1.0
		sprite.visible = sprite == next
	var animation := &"full_roll" if level == Load.FULL else &"empty_roll"
	if rolling:
		wheels.play(animation, wheel_speed_factor if level == Load.FULL else 1.0)
	else:
		wheels.stop()
		wheels.animation = animation
		wheels.frame = 0

	if animate_fill and not rolling and previous != next:
		previous.show()
		next.modulate.a = 0.0
		_fill_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_fill_tween.tween_property(next, "modulate:a", 1.0, fill_transition_seconds * 0.85)
		_fill_tween.tween_property(previous, "modulate:a", 0.0, fill_transition_seconds * 0.70).set_delay(
			fill_transition_seconds * 0.30)
		_fill_tween.chain().tween_callback(previous.hide)


func _load_art(level: Load) -> Node2D:
	match level:
		Load.SMALL:
			return small_load
		Load.HALF:
			return half_load
		_:
			return wheels
