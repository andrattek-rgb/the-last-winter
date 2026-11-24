extends SceneTree

const YARD := preload("res://scenes/rooms/parte_de_fora_2.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var yard := YARD.instantiate()
	root.add_child(yard)
	var light := yard.get_node("LuzDeVigia")
	light.set_physics_process(false)
	var first: Marker2D = light.sweep_points[0]
	_check(first.get_parent().name == &"Caixa04" and light.spot_center == first.global_position,
		"A luz começa na caixa 4.")
	for index in range(1, 4):
		var point: Marker2D = light.sweep_points[index]
		_check(point.get_parent().name == StringName("Caixa%02d" % (4 - index)),
			"A ordem do percurso é 4, 3, 2, 1.")
		for tick in 450:
			if light.destination > index:
				break
			light._advance_sweep(1.0 / 60.0)
		_check(light.spot_center == point.global_position, "A luz passa pela caixa %d." % (4 - index))
	light._advance_sweep(light.return_delay)
	_check(light.spot_center == first.global_position and light.destination == 1 and is_zero_approx(light.brightness),
		"A luz apaga no fim e volta à caixa 4.")

	light.brightness = 1.0
	var safe: Vector2 = light.safe_boundary.global_position
	light.spot_center = safe
	_check(not light.catches_at(safe - Vector2(1, 0)), "À esquerda da linha branca há proteção.")
	_check(light.catches_at(safe + Vector2(1, 0)), "A luz deteta o jogador exposto ao passar a linha.")
	_check(not light.catches_at(safe + Vector2(0, light.spot_radius.y + 5)),
		"Fora do círculo o jogador não é detetado.")

	var origin: Vector2 = light.shadow_origin.global_position
	for bounds: Rect2 in light.footprints:
		var center := bounds.get_center()
		var away := (center - origin).normalized()
		var hidden := center + away * 120.0
		var exposed := center - away * 135.0
		light.spot_center = hidden
		_check(not bounds.has_point(hidden) and not light.catches_at(hidden),
			"A sombra da caixa protege o jogador que está atrás dela.")
		if exposed.x >= safe.x:
			light.spot_center = exposed
			_check(light.catches_at(exposed), "À frente da caixa o jogador continua exposto.")

	var player: CharacterBody2D = light.player
	player.global_position = safe + Vector2(22, 0)
	light.spot_center = player.global_position
	light.destination = light.sweep_points.size()
	light._physics_process(light.detection_seconds + 0.001)
	_check(light.caught and light.caught_notice.visible and not player.is_physics_processing(),
		"A exposição contínua ativa a deteção.")
	await create_timer(0.85).timeout
	_check(not light.caught and player.is_physics_processing()
		and player.global_position.is_equal_approx(light.spawn.global_position),
		"Após a deteção, o jogador regressa à zona segura.")

	for failure in failures:
		push_error(failure)
	print("Luz da torre: %d falhas." % failures.size())
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
