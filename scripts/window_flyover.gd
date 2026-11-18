extends ColorRect

@export_range(0.0, 15.0) var first_delay := 3.0
@export_range(1.0, 12.0) var pass_duration := 4.3
@export_range(5.0, 120.0) var repeat_interval := 29.0

const OFFSCREEN_MARGIN := 220.0

@onready var projection: ShaderMaterial = material
@onready var window_projection: ShaderMaterial = $WindowBlur.material
@onready var elapsed := -first_delay


func _process(delta: float) -> void:
	elapsed += delta
	var cycle_time := fmod(elapsed, maxf(repeat_interval, pass_duration))
	var travel := clampf(cycle_time / pass_duration, 0.0, 1.0)
	var airplane_x := lerpf(-OFFSCREEN_MARGIN, size.x + OFFSCREEN_MARGIN, travel)
	projection.set_shader_parameter(&"airplane_x", airplane_x)
	window_projection.set_shader_parameter(&"airplane_x", airplane_x)
