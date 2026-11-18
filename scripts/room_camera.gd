extends Camera2D

@export var target: Node2D


func _ready() -> void:
	_follow_horizontal()
	reset_smoothing()


func _physics_process(_delta: float) -> void:
	_follow_horizontal()


func _follow_horizontal() -> void:
	if not is_instance_valid(target):
		return
	var half_width := get_viewport_rect().size.x / (2.0 * zoom.x)
	var left_center := limit_left + half_width
	var right_center := maxf(left_center, limit_right - half_width)
	global_position.x = clampf(target.global_position.x, left_center, right_center)
