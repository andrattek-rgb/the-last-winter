class_name GuardVision
extends Node

@export var convoy: LaundryConvoy
@export var crate_cover: StealthCover
@export var sight_start_x := 555.0
@export_range(32.0, 900.0) var sight_range := 315.0
@export_range(5.0, 175.0) var field_of_view := 136.0
@export_range(0.05, 3.0) var detection_seconds := 0.55

var exposure := 0.0


func update_exposure(delta: float, target: Vector2, crouched: bool) -> bool:
	if is_in_crate_cover(target):
		exposure = 0.0
	elif can_see(target, crouched):
		exposure = minf(exposure + delta, detection_seconds)
	else:
		exposure = maxf(0.0, exposure - delta * 2.5)
	return exposure >= detection_seconds - 0.000001


func can_see(target: Vector2, crouched: bool) -> bool:
	if target.x < sight_start_x or not convoy.guard_is_exposed():
		return false
	var origin := convoy.guard.global_position
	var toward := target - origin
	if toward.length_squared() > sight_range * sight_range:
		return false
	if not toward.is_zero_approx() and convoy.look_direction().dot(toward.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
		return false
	return not is_protected(origin, target, crouched)


func is_protected(observer: Vector2, target: Vector2, crouched: bool) -> bool:
	var cover := cover_at(target, observer)
	return (
		cover == convoy.cart.cover
		or (crate_cover != null and cover == crate_cover)
		or (cover == convoy.pile and crouched)
	)


func is_in_crate_cover(target: Vector2) -> bool:
	return (
		crate_cover != null
		and crate_cover.contains(target)
		and crate_cover.to_local(convoy.cart.global_position).x >= -crate_cover.size.x * 0.5
	)


func cover_at(target: Vector2, observer := Vector2.INF) -> StealthCover:
	var origin := convoy.guard.global_position if observer == Vector2.INF else observer
	if is_in_crate_cover(target):
		return crate_cover
	if convoy.cart.visible and convoy.cart.cover.covers_below_line(target):
		return convoy.cart.cover
	if convoy.pile.blocks_sight(origin, target):
		return convoy.pile
	return null
