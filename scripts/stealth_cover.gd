class_name StealthCover
extends Node2D

@export var size := Vector2(150, 40)

func covers_below_line(target: Vector2) -> bool:
	var point := to_local(target)
	return absf(point.x) <= size.x * 0.5 and point.y >= 0.0


func blocks_sight(origin: Vector2, target: Vector2) -> bool:
	var from := to_local(origin)
	var to := to_local(target)
	var bounds := Rect2(-size * 0.5, size)
	if bounds.has_point(from) or bounds.has_point(to):
		return false
	var corners := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y),
		bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	for index in corners.size():
		if Geometry2D.segment_intersects_segment(from, to, corners[index], corners[(index + 1) % 4]) != null:
			return true
	return false
