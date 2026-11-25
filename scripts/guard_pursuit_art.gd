@tool
extends AnimatedSprite2D

@export_group("Pursuit Scale")
@export var startled_scale := Vector2(0.78, 0.81):
	set(value):
		startled_scale = value
		_apply_scale()
@export var angry_scale := Vector2(0.78, 0.81):
	set(value):
		angry_scale = value
		_apply_scale()
@export var running_scale := Vector2(0.78, 0.81):
	set(value):
		running_scale = value
		_apply_scale()


func _ready() -> void:
	animation_changed.connect(_apply_scale)
	_apply_scale()


func _apply_scale() -> void:
	match animation:
		&"startled":
			scale = startled_scale
		&"angry":
			scale = angry_scale
		&"run":
			scale = running_scale
