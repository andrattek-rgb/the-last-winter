extends SceneTree

const KITCHEN := preload("res://scenes/rooms/kitchen.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var kitchen := KITCHEN.instantiate()
	root.add_child(kitchen)
	current_scene = kitchen
	var player: CharacterBody2D = kitchen.player
	var interaction: KitchenInteraction = kitchen.interaction
	var stirrer: Node2D = kitchen.get_node("EmCena/Mexedor")
	var diner: AnimatedSprite2D = kitchen.get_node("EmCena/MesaComensal/Sprite")
	var pair: AnimatedSprite2D = kitchen.get_node("EmCena/MesaDupla/Sprite")
	var server: AnimatedSprite2D = kitchen.get_node("EmCena/Balcao/Servidor")
	var walk: AnimatedSprite2D = stirrer.get_node("Sprite")
	_check(diner.is_playing() and pair.is_playing() and diner.frame != pair.frame, "Os comensais começam desfasados.")
	_check(diner.sprite_frames.get_frame_count(&"comer") == 16
		and is_equal_approx(diner.sprite_frames.get_animation_speed(&"comer"), 2.192),
		"O comensal sozinho usa os fotogramas e o ritmo originais.")
	_check(pair.sprite_frames.get_frame_count(&"comer") == 48,
		"A mesa dupla mantém os fotogramas intermédios.")
	_check(server.is_playing() and server.animation == &"idle" and server.sprite_frames.get_frame_count(&"idle") == 48,
		"O novo idle do balcão arranca automaticamente.")
	var camera: Camera2D = kitchen.get_node("Camera")
	var idle_size := server.sprite_frames.get_frame_texture(&"idle", 0).get_size()
	var right_edge := server.to_global(server.offset + Vector2(idle_size.x * 0.5, 0.0)).x
	_check(right_edge <= camera.limit_right + 2.0, "O limite da câmara não corta visivelmente o balcão.")
	_check(walk.sprite_frames.get_frame_count(&"caminhar") == 16
		and is_equal_approx(walk.sprite_frames.get_animation_speed(&"caminhar"), 3.582),
		"A caminhada do mexedor usa os fotogramas e o ritmo originais.")
	_check(stirrer.stations.size() == 3, "Há três caldeirões no percurso editável.")
	_check(kitchen.get_node("EmCena").y_sort_enabled, "A profundidade segue a posição no chão.")

	await _ticks(10)
	_check(kitchen.get_node("Filme/Filtro").size == root.get_visible_rect().size
		and kitchen.arrival_fade.size == root.get_visible_rect().size,
		"O filtro e a transição cobrem o enquadramento inteiro.")
	for fixture in ["Caldeirao01", "Caldeirao02", "Caldeirao03", "MesaComensal", "MesaDupla"]:
		var body: StaticBody2D = kitchen.get_node("EmCena/" + fixture)
		var feet := body.global_position
		var query := PhysicsRayQueryParameters2D.create(feet + Vector2(0, 30), feet + Vector2(0, -15), 1)
		var hit := body.get_world_2d().direct_space_state.intersect_ray(query)
		_check(hit.get("collider") == body, "Tem colisão: " + fixture)
	await _interact()
	_check(interaction.state == KitchenInteraction.State.FINISHED and player.is_physics_processing(),
		"A interação está fora de alcance no ponto de partida.")
	Input.action_press(&"move_right")
	for tick in 420:
		await physics_frame
		if player.global_position.x >= kitchen.area.global_position.x:
			break
	Input.action_release(&"move_right")
	await _ticks(4)
	_check(kitchen.prompt.visible and kitchen.area.overlaps_body(player), "É possível chegar à indicação do balcão.")
	_check(player.test_move(player.global_transform, Vector2(0, -100)), "O balcão tem colisão.")
	await _interact()
	_check(interaction.state == KitchenInteraction.State.IDLE_CHOICE
		and interaction.video.stream == interaction.idle_video and interaction.choices.visible
		and not player.is_physics_processing(), "E bloqueia o movimento e abre o vídeo em loop.")

	var wrap_observed := false
	var previous := 0.0
	for tick in 500:
		await process_frame
		var position := interaction.video.stream_position
		if previous > 4.0 and position < 1.0:
			wrap_observed = true
			break
		previous = position
	_check(wrap_observed and interaction.video.is_playing() and interaction.choices.visible
		and not player.is_physics_processing(), "O vídeo idle repete sem fechar as opções.")

	var button := interaction.bread_button
	await _click(button.get_global_transform_with_canvas() * (button.size * 0.5))
	_check(interaction.state == KitchenInteraction.State.SERVING_BREAD and not interaction.video.loop
		and interaction.video.stream == interaction.bread_video and not interaction.choices.visible,
		"Pão abre só a entrega de pão.")
	interaction.choose_soup()
	_check(interaction.video.stream == interaction.bread_video, "Uma escolha repetida não interrompe a entrega.")
	await _wait_for_serving(interaction)
	_check(kitchen.received_food == [&"pao"] and player.is_physics_processing(),
		"A entrega de pão completa uma vez e devolve o controlo.")

	await _interact()
	await _press_key(KEY_RIGHT)
	_check(interaction.soup_button.has_focus(), "As setas mudam a opção com foco.")
	await _press_key(KEY_ENTER)
	_check(interaction.state == KitchenInteraction.State.SERVING_SOUP and not interaction.video.loop
		and interaction.video.stream == interaction.soup_video, "O teclado seleciona só a entrega de sopa.")
	await _wait_for_serving(interaction)
	_check(kitchen.received_food == [&"pao", &"sopa"] and player.is_physics_processing(),
		"A entrega de sopa completa uma vez e devolve o controlo.")

	stirrer.stations[0].station.position.x -= 13.0
	var visited: Array[int] = []
	for tick in 1900:
		await physics_frame
		var index: int = stirrer.station_index
		var station: KitchenCauldron = stirrer.stations[index]
		if station.stirring.visible and (visited.is_empty() or visited[-1] != index):
			_check(stirrer.global_position.is_equal_approx(station.station.global_position)
				and station.stirring.is_playing() and not station.stove.visible,
				"O mexedor usa a marca editável e o caldeirão certo.")
			_check(station.stirring.sprite_frames.get_frame_count(&"mexer") == 16
				and is_equal_approx(station.stirring.sprite_frames.get_animation_speed(&"mexer"), 3.582),
				"O mexedor usa a animação original no caldeirão.")
			visited.append(index)
			if visited.size() == 4:
				break
	_check(visited.size() == 4 and visited[0] == visited[3], "O mexedor repete o circuito dos três caldeirões.")

	Input.action_press(&"move_right")
	for tick in 110:
		await physics_frame
		if not is_instance_valid(kitchen) or kitchen.leaving:
			break
	Input.action_release(&"move_right")
	for tick in 120:
		await process_frame
		if current_scene != null and current_scene.name == &"ParteDeFora2":
			break
	_check(current_scene != null and current_scene.name == &"ParteDeFora2",
		"A saída também funciona ao executar a cozinha isoladamente.")

	for failure in failures:
		push_error(failure)
	print("Cozinha: %d falhas." % failures.size())
	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _wait_for_serving(interaction: KitchenInteraction) -> void:
	for tick in 620:
		await process_frame
		if interaction.state == KitchenInteraction.State.FINISHED:
			break


func _interact() -> void:
	await _press_key(KEY_E)


func _press_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var released := event.duplicate() as InputEventKey
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _click(point: Vector2) -> void:
	for is_pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = is_pressed
		root.push_input(event, true)
		await process_frame


func _ticks(count: int) -> void:
	for tick in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
