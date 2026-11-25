extends SceneTree

const YARD := preload("res://scenes/rooms/parte_de_fora_2.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var yard := YARD.instantiate()
	var light := yard.get_node("LuzDeVigia")
	light.random.seed = 1623
	root.add_child(yard)
	light.set_physics_process(false)
	var player: CharacterBody2D = light.player
	_check(player.get("horizontal_speed") == 260.0 and player.get("depth_speed") == 165.0,
		"O jogador usa a velocidade padrão nos dois eixos.")
	var first: Marker2D = light.sweep_points[0]
	_check(first.get_parent().name == &"Caixa04" and light.spot_center == first.global_position,
		"A luz começa na caixa 4.")
	var beam: Polygon2D = light.beam
	var lamp_glow: Sprite2D = light.lamp_glow
	_check(beam.to_global(beam.polygon[5]).is_equal_approx(light.emitter.global_position)
		and lamp_glow.global_position.is_equal_approx(light.emitter.global_position),
		"O feixe e o brilho partem da lâmpada na cabine.")
	var current := 0
	var visited := {current: true}
	var largest_step := 0.0
	var jumps_a_box := false
	var shortest_pause := 1.0
	var longest_pause := 1.0
	var step := 1.0 / 60.0
	for stop in 15:
		var index: int = light.destination
		_check(not visited.has(index), "Cada ronda cobre todas as caixas sem repetir paragens.")
		jumps_a_box = jumps_a_box or absi(index - current) > 1
		var goal: Vector2 = light.sweep_points[index].global_position
		var stopped_at: Vector2 = light.spot_center
		var pause: float = light.hold_remaining
		_check(pause >= 0.70 and pause <= 1.30, "As pausas respeitam a duração configurada.")
		shortest_pause = minf(shortest_pause, pause)
		longest_pause = maxf(longest_pause, pause)
		light._advance_sweep(pause)
		_check(light.spot_center == stopped_at, "O feixe fica parado durante a pausa sorteada.")
		for tick in 420:
			var previous: Vector2 = light.spot_center
			light._advance_sweep(step)
			largest_step = maxf(largest_step, previous.distance_to(light.spot_center))
			if light.spot_center == goal:
				break
		_check(light.spot_center == goal and light.destination != index,
			"O feixe chega à caixa sorteada e escolhe outra paragem.")
		current = index
		visited[current] = true
		if visited.size() == 4:
			visited = {current: true}
	_check(jumps_a_box and longest_pause - shortest_pause > 0.25,
		"A rota e a duração das pausas variam ao longo das rondas.")
	_check(absf(largest_step - light.sweep_speed * step) < 0.002,
		"O feixe mantém a velocidade de deslocação sem saltar entre caixas.")

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

	player.global_position = safe + Vector2(22, 0)
	light.spot_center = player.global_position
	light.hold_remaining = light.detection_seconds + 0.1
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
