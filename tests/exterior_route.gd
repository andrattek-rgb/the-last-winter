extends SceneTree

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	_test_route.call_deferred()


func _test_route() -> void:
	var game := MAIN.instantiate()
	root.add_child(game)
	var room := game.get_node("Room01")
	var indoor_film: ColorRect = room.get_node("FilmEffect/Filter")
	_check(indoor_film.get_global_rect().is_equal_approx(root.get_visible_rect()),
		"O filtro da Sala 1 começa na origem e cobre todo o ecrã.")
	var inside_player: CharacterBody2D = room.get_node("Characters/Player")
	_check(inside_player.position.x < 250.0, "O jogo começa no barracão.")

	Input.action_press(&"move_right")
	for tick in range(540):
		await physics_frame
		if game.get("transitioning"):
			break
	Input.action_release(&"move_right")
	await process_frame
	await process_frame

	var outside := game.get_node_or_null("ParteDeFora")
	_check(outside != null and not game.has_node("Room01"), "Atravessar o extremo direito abre o exterior uma vez.")
	if outside != null:
		var outdoor_film: ColorRect = outside.get_node("FilmeAntigo/Filtro")
		_check(outdoor_film.get_global_rect().is_equal_approx(root.get_visible_rect()),
			"O filtro do primeiro pátio começa na origem e cobre todo o ecrã.")
		outside.get_node("Desafio/VisaoDoGuarda").sight_range = 0.0
		outside.dog_sight_range = 0.0
		var player: CharacterBody2D = outside.get_node("Personagens/Player")
		var arrival: Marker2D = outside.get_node("ChegadaDoBarracao")
		_check(is_zero_approx(player.global_rotation) and is_zero_approx(player.global_skew),
			"O protagonista chega ao pátio direito, sem rotação ou inclinação.")
		_check(player.global_position.is_equal_approx(arrival.global_position) and arrival.position.x < 575.0,
			"O jogador aparece junto à porta fechada da esquerda.")
		var ground: Sprite2D = outside.get_node("Paisagem/Chao")
		_check(ground.texture.resource_path.ends_with("/chao_nevado.png"), "O pátio usa o novo chão nevado.")
		await _hold(&"move_back", 55)
		_check(player.position.y > 690.0, "O jogador não atravessa a porta fechada.")
		await _hold(&"move_forward", 230)
		var perimeter: CollisionPolygon2D = outside.get_node("LimitesDoPatio/Perimetro")
		_check(_at_boundary(player, perimeter, Vector2.DOWN), "O jogador não sai pela frente.")

		await _hold(&"move_right", 62)
		await _hold(&"move_back", 150)
		_check(_at_boundary(player, perimeter, Vector2.UP), "O perímetro limita o fundo do pátio.")
		await _hold(&"move_forward", 22)
		_check(not player.test_move(player.global_transform, Vector2(510, 0)),
			"É possível atravessar o chão onde ficava a poça central.")
		var crate_base: CollisionShape2D = outside.get_node("Personagens/Caixa01/Corpo/BaseDaCaixa")
		var crate_shape := crate_base.shape as RectangleShape2D
		var crate_front := (crate_base.global_transform * Rect2(-crate_shape.size * 0.5, crate_shape.size)).end.y
		var clearance := maxf(0.0, crate_front + 25.0 - player.global_position.y)
		await _hold(&"move_forward", ceili(clearance * 60.0 / float(player.get("depth_speed"))))
		await _hold(&"move_right", 248)
		_check(not outside.get("entering"), "Mover para a direita não ativa a porta aberta.")
		Input.action_press(&"move_back")
		for tick in 160:
			await physics_frame
			if game.has_node("Kitchen"):
				break
		Input.action_release(&"move_back")
		var kitchen := game.get_node_or_null("Kitchen")
		_check(kitchen != null and not game.has_node("ParteDeFora"),
			"Subir os degraus abre a cozinha no jogo.")
		if kitchen != null:
			Input.action_press(&"move_right")
			for tick in 450:
				await physics_frame
				if not is_instance_valid(kitchen) or kitchen.leaving:
					break
			Input.action_release(&"move_right")
			for tick in 120:
				await process_frame
				if game.has_node("ParteDeFora2"):
					break
			var yard := game.get_node_or_null("ParteDeFora2")
			_check(yard != null and not game.has_node("Kitchen"), "Seguir até ao extremo direito da cozinha abre o segundo pátio.")
			if yard != null:
				var searchlight := yard.get_node("LuzDeVigia")
				_check(yard.player.global_position.is_equal_approx(yard.arrival.global_position)
					and yard.player.global_position.x < searchlight.safe_boundary.global_position.x,
					"O jogador chega à zona segura do segundo pátio.")
				_check(yard.get_node("Neve").emitting
					and yard.get_node("FilmeAntigo/Filtro").material.shader.resource_path.ends_with("/old_film.gdshader"),
					"O segundo pátio tem neve a cair e o filtro de filme antigo.")

	for failure in failures:
		push_error(failure)
	print("Percurso do barracão ao exterior: %d falhas." % failures.size())
	quit(0 if failures.is_empty() else 1)


func _at_boundary(player: CharacterBody2D, perimeter: CollisionPolygon2D, direction: Vector2) -> bool:
	var feet := player.global_position
	var query := PhysicsRayQueryParameters2D.create(feet, feet + direction * 16.0, player.collision_mask)
	var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
	var boundary_body := perimeter.get_parent() as StaticBody2D
	if hit.get("collider") != boundary_body:
		return false
	return boundary_body.shape_owner_get_owner(boundary_body.shape_find_owner(hit.shape)) == perimeter


func _hold(action: StringName, ticks: int) -> void:
	Input.action_press(action)
	for tick in range(ticks):
		await physics_frame
	Input.action_release(action)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
