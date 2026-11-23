extends SceneTree

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	_test_route.call_deferred()


func _test_route() -> void:
	var game := MAIN.instantiate()
	root.add_child(game)
	var room := game.get_node("Room01")
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
		outside.get_node("Desafio/VisaoDoGuarda").sight_range = 0.0
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
		await _hold(&"move_forward", 40)
		await _hold(&"move_right", 248)
		_check(not outside.get("entering"), "Mover para a direita não ativa a porta aberta.")
		await _hold(&"move_back", 160)
		var kitchen := game.get_node_or_null("Kitchen")
		_check(kitchen != null and not game.has_node("ParteDeFora"),
			"Subir os degraus abre a cozinha no jogo.")

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
