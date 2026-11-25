extends SceneTree

const OUTSIDE := preload("res://scenes/rooms/parte_de_fora.tscn")
const PHASE := LaundryConvoy.Phase
const LOAD := LaundryCart.Load

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := OUTSIDE.instantiate()
	var worker_base_scale: Vector2 = scene.get_node("Personagens/PrisioneiroTrabalhador").scale
	root.add_child(scene)
	var convoy: LaundryConvoy = scene.get_node("Desafio")
	var vision: GuardVision = scene.get_node("Desafio/VisaoDoGuarda")
	var player: CharacterBody2D = scene.get_node("Personagens/Player")
	_check_guard_scales(scene.guard_chase.art)
	convoy.set_physics_process(false)
	scene.set_physics_process(false)
	var start := convoy.worker.global_position
	var cart_start := convoy.cart.global_position
	var guard_start := convoy.guard.global_position
	_check_frames(convoy)
	_check(convoy.phase == PHASE.WAITING_TO_LOAD and convoy.worker.animation == &"idle",
		"O trabalhador espera antes de carregar.")
	convoy._physics_process(convoy.idle_seconds - 0.01)
	_check(convoy.phase == PHASE.WAITING_TO_LOAD, "A primeira pausa ainda está ativa.")
	convoy._physics_process(0.01)
	_check(convoy.phase == PHASE.LOADING and convoy.cart.load_level == LOAD.EMPTY,
		"O ciclo começa a carregar com o carrinho vazio.")
	_check((convoy.worker.scale * convoy._load_frame_ratio).is_equal_approx(worker_base_scale * convoy.worker_load_scale),
		"O tamanho extra é aplicado ao trabalhador enquanto carrega roupa.")

	await physics_frame
	Input.action_press(&"crouch")
	await physics_frame
	await physics_frame
	_check(player.crouched and player.get_node("Sprite").animation == &"crouch_idle",
		"C agacha o jogador com a animação própria.")
	Input.action_release(&"crouch")

	var at_blue_line := Vector2(vision.sight_start_x + 2.0, convoy.cart.cover.global_position.y - 24.0)
	_check(not vision.can_see(at_blue_line - Vector2(4, 0), false) and vision.can_see(at_blue_line, false),
		"A linha azul delimita a visão do guarda.")
	convoy._physics_process(1.5)
	_check(convoy.cart.load_level == LOAD.SMALL, "O primeiro nível de carga é visível.")
	var fill_blend := convoy.cart._fill_tween
	fill_blend.pause()
	fill_blend.custom_step(convoy.cart.fill_transition_seconds * 0.50)
	_check(convoy.cart.wheels.visible and convoy.cart.small_load.visible
		and convoy.cart.small_load.modulate.a > 0.0 and convoy.cart.small_load.modulate.a < 1.0,
		"A roupa aparece gradualmente e o carrinho continua visível.")
	fill_blend.custom_step(convoy.cart.fill_transition_seconds)
	_check(not convoy.cart.wheels.visible and is_equal_approx(convoy.cart.small_load.modulate.a, 1.0),
		"A mistura termina com apenas o novo estado visível.")
	convoy._physics_process(1.7)
	_check(convoy.cart.load_level == LOAD.HALF, "O segundo nível de carga é visível.")
	convoy._physics_process(2.79)
	_check(convoy.phase == PHASE.LOADING and convoy.cart.load_level == LOAD.FULL,
		"O carrinho está cheio e o trabalhador ainda carrega antes dos 6 s.")
	convoy._physics_process(0.01)
	_check(convoy.phase == PHASE.APPROACHING_HANDLES and convoy.worker.animation == &"walk",
		"Aos 6 s o trabalhador começa a caminhar até às pegas.")
	_check(convoy.worker.scale.is_equal_approx(worker_base_scale),
		"A caminhada até às pegas usa a escala original.")
	var approach_seconds := convoy._maneuver_duration
	convoy._physics_process(approach_seconds * 0.5)
	_check(convoy.cart.global_position.is_equal_approx(cart_start) and not convoy.cart.wheels.is_playing()
		and convoy.worker.global_position.distance_to(start) > 10.0, "O trabalhador anda enquanto o carrinho fica parado.")
	convoy._physics_process(approach_seconds * 0.5)
	_check(convoy.phase == PHASE.WAITING_AT_HANDLES and convoy.worker.animation == &"idle"
		and not convoy.cart.wheels.is_playing(), "O trabalhador espera junto das pegas.")
	convoy._physics_process(convoy.idle_seconds)
	_check(convoy.phase == PHASE.PULLING_FULL and convoy.worker.animation == &"pull_back"
		and convoy.cart.wheels.animation == &"full_roll", "As rodas começam a rolar depois de chegar às pegas.")
	var worker_cart_gap := convoy.worker.global_position - convoy.cart.global_position
	convoy._physics_process(2.2)
	_check(convoy.worker.global_position.x > start.x and convoy.guard.animation == &"guard_idle_impatient"
		and convoy.guard.global_position.is_equal_approx(guard_start),
		"O guarda espera pelo carrinho até à linha branca.")
	_check((convoy.worker.global_position - convoy.cart.global_position).is_equal_approx(worker_cart_gap)
		and convoy.cart.handles.global_position.x > convoy.cart.global_position.x
		and convoy.worker.global_position.x > convoy.cart.handles.global_position.x
		and convoy.worker.flip_h and is_equal_approx(convoy.distance, 2.2 * convoy.pull_speed),
		"O trabalhador recua à direita das pegas à velocidade de puxar.")

	var cart_shadow := convoy.cart.cover.to_global(Vector2(0, 52)) - convoy.cart.global_position
	var behind_cart := convoy.cart.global_position + cart_shadow
	_check(not vision.can_see(behind_cart, false) and not vision.can_see(behind_cart, true),
		"O lado vermelho protege em ambas as posturas.")
	scene._show_cover(convoy.cart.cover)
	_check(convoy.cart.art.z_index == 0, "A furtividade conserva a profundidade visual do carrinho.")
	var above_line := convoy.cart.cover.to_global(Vector2(0, -8))
	_check(vision.can_see(above_line, false), "O guarda consegue ver do lado azul.")
	_check(vision.cover_at(behind_cart + Vector2(0, 90)) == convoy.cart.cover
		and vision.cover_at(convoy.cart.cover.to_global(Vector2(55, 52))) != convoy.cart.cover,
		"A faixa vermelha estende-se para baixo e conserva os limites laterais.")
	convoy.cart.set_load(LOAD.EMPTY)
	_check(not vision.can_see(behind_cart, true) and vision.can_see(above_line, true),
		"O carrinho vazio mantém a mesma linha de visão.")
	convoy.cart.set_load(LOAD.FULL, true)

	player.global_position = behind_cart
	Input.action_press(&"crouch")
	var stayed_covered := true
	var walked := false
	for tick in 48:
		if player.global_position.x < convoy.cart.global_position.x + cart_shadow.x:
			Input.action_press(&"move_right")
		else:
			Input.action_release(&"move_right")
		convoy._physics_process(1.0 / 60.0)
		await physics_frame
		stayed_covered = stayed_covered and not vision.can_see(player.global_position, player.crouched)
		walked = walked or player.get_node("Sprite").animation == &"crouch_walk"
	Input.action_release(&"move_right")
	Input.action_release(&"crouch")
	_check(stayed_covered and walked and player.global_position.x > behind_cart.x + 25.0,
		"O jogador acompanha manualmente o carrinho enquanto caminha agachado.")

	var route_length := convoy.route.curve.get_baked_length()
	var before_gate := convoy._follow_distance - 5.0
	convoy._physics_process((before_gate - convoy.distance) / convoy.pull_speed)
	_check(convoy.cart.global_position.x < convoy.guard_follow_from_x
		and convoy.guard.global_position.is_equal_approx(guard_start), "O guarda mantém a posição antes da linha branca.")
	convoy._physics_process(10.0 / convoy.pull_speed)
	_check(convoy.cart.global_position.x > convoy.guard_follow_from_x
		and convoy.guard.global_position.distance_to(guard_start) < 20.0
		and convoy.guard.animation == &"guard_walk"
		and convoy.guard.global_position.distance_to(convoy.worker.global_position) > 120.0,
		"O guarda só sai ao cruzar a linha branca e acompanha de uma faixa afastada.")
	_check(convoy.guard.z_index < convoy.cart.z_index and convoy.guard_is_exposed(),
		"O guarda anda atrás da camada do carrinho e continua a vigiar o pátio.")
	player.global_position = convoy.cart.cover.to_global(Vector2(0, 52))
	Input.action_press(&"crouch")
	var protected_to_stop := true
	for tick in 260:
		if convoy.phase == PHASE.PAUSED_AT_BARRACK:
			break
		if player.global_position.x < convoy.cart.cover.global_position.x:
			Input.action_press(&"move_right")
		else:
			Input.action_release(&"move_right")
		convoy._physics_process(1.0 / 60.0)
		await physics_frame
		protected_to_stop = protected_to_stop and vision.cover_at(player.global_position) == convoy.cart.cover
	Input.action_release(&"move_right")
	Input.action_release(&"crouch")
	_check(protected_to_stop and convoy.phase == PHASE.PAUSED_AT_BARRACK,
		"O jogador acompanha a cobertura móvel com os controlos até à paragem.")
	_check(convoy.phase == PHASE.PAUSED_AT_BARRACK and convoy.worker.animation == &"idle"
		and convoy.guard.animation == &"guard_idle_impatient" and not convoy.cart.wheels.is_playing()
		and convoy.guard.global_position.is_equal_approx(convoy.guard_stop.global_position),
		"O conjunto espera junto ao barracão, nas marcas da imagem.")
	var parked := convoy.cart.global_position
	convoy._physics_process(convoy.stop_seconds - convoy.elapsed - 0.01)
	_check(convoy.phase == PHASE.PAUSED_AT_BARRACK and convoy.cart.global_position.is_equal_approx(parked),
		"A pausa de três segundos mantém o carrinho no sítio.")
	convoy._physics_process(0.01)
	_check(convoy.phase == PHASE.PULLING_FULL and convoy.cart.wheels.is_playing(),
		"O guarda e o carrinho prosseguem após a pausa.")
	convoy._physics_process((route_length - convoy.distance) / convoy.pull_speed)
	_check(convoy.phase == PHASE.HIDDEN_BEHIND_BARRACK and not convoy.worker.visible
		and not convoy.guard.visible and not convoy.cart.visible
		and convoy.worker.z_index < convoy.building.z_index
		and convoy.guard.z_index < convoy.cart.z_index,
		"O conjunto fica em profundidade atrás do barracão.")
	convoy._physics_process(2.99)
	_check(convoy.phase == PHASE.HIDDEN_BEHIND_BARRACK, "O conjunto espera os 3 s completos.")
	convoy._physics_process(0.01)
	_check(convoy.phase == PHASE.RETURNING_EMPTY and convoy.worker.animation == &"push_cart"
		and convoy.cart.wheels.animation == &"empty_roll" and convoy.guard.flip_h,
		"O regresso começa com rodas vazias e o guarda voltado para a esquerda.")
	convoy._physics_process(0.5)
	_check(is_equal_approx(route_length - convoy.distance, 0.5 * convoy.travel_speed)
		and convoy.worker.get_playing_speed() == 1.0, "O regresso usa a velocidade normal.")
	_check(vision.cover_at(convoy.cart.cover.to_global(Vector2(0, 52))) == convoy.cart.cover
		and vision.cover_at(convoy.cart.cover.to_global(Vector2(0, -8))) != convoy.cart.cover,
		"A divisão acompanha o carrinho vazio no regresso.")
	convoy._physics_process(convoy.distance / convoy.travel_speed)
	_check(convoy.phase == PHASE.POSITIONING and convoy.cart.global_position.is_equal_approx(cart_start),
		"O carrinho volta ao lugar inicial sem salto de posição.")
	convoy._physics_process(convoy._maneuver_duration)
	_check(convoy.phase == PHASE.WAITING_TO_LOAD, "O novo ciclo repete a pausa antes de carregar.")
	convoy._physics_process(convoy.idle_seconds)
	_check(convoy.phase == PHASE.LOADING and convoy.worker.global_position.is_equal_approx(start)
		and convoy.guard.global_position.is_equal_approx(guard_start) and convoy.cart.load_level == LOAD.EMPTY,
		"Trabalhador e guarda voltam ao ponto inicial e o ciclo repete.")
	_check((convoy.worker.scale * convoy._load_frame_ratio).is_equal_approx(worker_base_scale * convoy.worker_load_scale),
		"O tamanho de carregamento não acumula a cada ciclo.")

	player.global_position = Vector2(720, 820)
	convoy.set_physics_process(true)
	scene.set_physics_process(true)
	await _ticks(43)
	_check(scene.pursuer == scene.guard_chase and scene.guard_chase.art.animation == &"startled"
		and not convoy.guard.visible, "O guarda reage à exposição contínua antes de perseguir.")
	_check(convoy.is_physics_processing() and convoy.worker.is_playing() and convoy.elapsed > 0.6,
		"O trabalhador continua a animar e a carregar roupa quando o guarda vê o jogador.")
	await _check_capture(scene, scene.guard_chase)
	convoy.set_physics_process(false)

	var dog: YardPursuer = scene.dog
	_check(dog.art.sprite_frames.get_frame_count(&"startled") == 7
		and dog.art.sprite_frames.get_frame_count(&"angry") == 7
		and scene.guard_chase.art.sprite_frames.get_frame_count(&"run") == 16,
		"As animações de reação usam os novos spritesheets.")
	var exposed_to_dog := Vector2(dog.global_position.x - 145.0, scene.dog_chase_ground_y + 38.0)
	_check(dog.art.animation == &"sleep" and not scene._dog_can_see(exposed_to_dog),
		"O cão dorme e não vigia enquanto o guarda está no posto.")
	convoy._physics_process(convoy.idle_seconds * 2.0 + convoy.load_seconds + approach_seconds
		+ (convoy._follow_distance + 20.0) / convoy.pull_speed)
	var guard_range := vision.sight_range
	vision.sight_range = 0.0
	player.global_position = convoy.cart.cover.to_global(Vector2(0, 25))
	_check(dog.global_position.distance_to(player.global_position) < scene.dog_sight_range
		and convoy.guard_is_escorting() and not scene._dog_can_see(player.global_position),
		"O carrinho protege o jogador mesmo com o cão perto e o guarda fora do posto.")
	await _ticks(40)
	_check(scene.pursuer == null and dog.art.animation == &"sleep",
		"O cão continua a dormir quando o jogador acompanha o carrinho pelo lado protegido.")
	player.global_position = exposed_to_dog
	_check(scene._dog_can_see(exposed_to_dog), "O cão vigia quando o guarda acompanha o carrinho.")
	var cart_before_dog := convoy.cart.global_position
	convoy.set_physics_process(true)
	await _ticks(27)
	_check(scene.pursuer == dog and dog.art.animation == &"startled",
		"Avançar fora da cobertura acorda o cão.")
	_check(convoy.guard.visible and convoy.worker.is_playing() and convoy.cart.wheels.is_playing()
		and convoy.cart.global_position.distance_to(cart_before_dog) > 16.0,
		"Durante a perseguição do cão, guarda, trabalhador e carrinho continuam a ronda.")
	await _check_capture(scene, dog)
	convoy.set_physics_process(false)
	_check(dog.global_position.is_equal_approx(scene.dog_home) and dog.art.animation == &"sleep",
		"Depois de apanhar o jogador, o cão volta ao posto e adormece.")

	convoy._physics_process(convoy.idle_seconds * 2.0 + convoy.load_seconds + approach_seconds
		+ (convoy._follow_distance + 20.0) / convoy.pull_speed)
	player.global_position = exposed_to_dog
	for tick in 150:
		if dog.art.animation == &"run" and dog.global_position.x < scene.dog_home.x - 16.0:
			break
		await physics_frame
	_check(scene.pursuer == dog and dog.global_position.y >= scene.dog_chase_ground_y,
		"O cão sai do posto acima do perímetro e entra na zona caminhável.")
	player.global_position = convoy.cart.cover.to_global(Vector2(0, 44))
	await _ticks(70)
	_check(scene.pursuer == null and not scene.caught and not scene.dog_returning
		and dog.global_position.is_equal_approx(scene.dog_home) and dog.art.animation == &"sleep",
		"A cobertura interrompe a perseguição e o cão regressa ao posto sem capturar o jogador.")

	player.global_position = Vector2(1550, 822)
	dog.global_position = Vector2(1320, 822)
	scene._begin_pursuit(dog)
	await _check_capture(scene, dog)

	vision.sight_range = guard_range
	await _check_crate_cover(scene, convoy, vision)
	convoy.restart_at_pile()
	convoy.set_physics_process(true)
	Input.action_press(&"move_forward")
	await _ticks(37)
	Input.action_release(&"move_forward")
	Input.action_press(&"crouch")
	for tick in 2500:
		if scene.pursuer != null or player.global_position.x >= 1575.0:
			break
		if player.global_position.x < convoy.cart.cover.global_position.x:
			Input.action_press(&"move_right")
		else:
			Input.action_release(&"move_right")
		await physics_frame
	Input.action_release(&"move_right")
	Input.action_press(&"move_back")
	await _ticks(74)
	Input.action_release(&"move_back")
	Input.action_release(&"crouch")
	_check(scene.entering and not player.visible,
		"É possível acompanhar o carrinho, contornar a caixa e entrar na cozinha com os dois vigilantes ativos.")

	for failure in failures:
		push_error(failure)
	print("Furtividade no pátio: %d falhas." % failures.size())
	quit(0 if failures.is_empty() else 1)


func _check_frames(convoy: LaundryConvoy) -> void:
	var frames := convoy.worker.sprite_frames
	var last_pull: AtlasTexture = frames.get_frame_texture(&"pull_back", 133)
	var first_pull: AtlasTexture = frames.get_frame_texture(&"pull_back", 0)
	_check(last_pull.region.position == Vector2(2, 2)
		and last_pull.atlas.resource_path.ends_with("_hd_01.png")
		and first_pull.atlas.resource_path.ends_with("_hd_03.png"),
		"A sequência de puxar está invertida no tempo.")
	_check(frames.get_frame_count(&"push_cart") == 268
		and convoy.guard.sprite_frames.get_frame_count(&"guard_idle_impatient") == 107,
		"As folhas com comprimentos diferentes usam todos os fotogramas úteis.")
	for sprite: AnimatedSprite2D in [convoy.worker, convoy.guard, convoy.cart.wheels]:
		for animation in sprite.sprite_frames.get_animation_names():
			for frame in sprite.sprite_frames.get_frame_count(animation):
				var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(animation, frame)
				_check(Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region),
					"O recorte %s/%d pertence à folha importada." % [animation, frame])


func _check_capture(scene: Node2D, actor: YardPursuer) -> void:
	var origin := actor.global_position
	var angry := false
	var runs := false
	for tick in 210:
		if scene.caught:
			break
		angry = angry or actor.art.animation == &"angry"
		runs = runs or actor.art.animation == &"run"
		await physics_frame
	_check(angry and runs and actor.global_position.distance_to(origin) > 35.0 and scene.caught,
		"O perseguidor fica furioso, corre e só captura ao chegar ao jogador.")
	await _ticks(40)
	_check(not scene.caught and scene.pursuer == null and scene.player.is_physics_processing()
		and scene.player.global_position.is_equal_approx(scene.arrival.global_position)
		and scene.vision.convoy.phase == PHASE.WAITING_TO_LOAD,
		"A captura reinicia o jogador e o percurso junto ao primeiro barracão.")


func _check_guard_scales(art: AnimatedSprite2D) -> void:
	var original_animation := art.animation
	var fields := ["startled_scale", "angry_scale", "running_scale"]
	var original_scales: Array[Vector2] = []
	for property in fields:
		original_scales.append(art.get(property))
	_check(art.position.length() < 15.0, "A arte da perseguição está alinhada com o guarda que a carrega.")
	art.animation = &"startled"
	art.set("startled_scale", Vector2(0.7, 0.72))
	art.set("angry_scale", Vector2(0.8, 0.82))
	art.set("running_scale", Vector2(0.9, 0.92))
	_check(art.scale.is_equal_approx(Vector2(0.7, 0.72)), "Editar a escala do susto atualiza a pose visível.")
	art.play(&"angry")
	_check(art.scale.is_equal_approx(Vector2(0.8, 0.82)), "A raiva usa a sua própria escala.")
	art.play(&"run")
	_check(art.scale.is_equal_approx(Vector2(0.9, 0.92)), "A corrida usa a sua própria escala.")
	for index in fields.size():
		art.set(fields[index], original_scales[index])
	art.stop()
	art.animation = original_animation


func _check_crate_cover(scene: Node2D, convoy: LaundryConvoy, vision: GuardVision) -> void:
	var crate := vision.crate_cover
	var refuge := crate.to_global(Vector2(250, 20))
	var front := Vector2(refuge.x, 860.0)
	var crate_edge := crate.to_global(Vector2(-crate.size.x * 0.5, 0.0)).x
	convoy.distance = convoy._distance_at_x(crate_edge - 5.0)
	convoy._place_trip(false)
	_check(not vision.is_in_crate_cover(refuge) and vision.can_see(refuge, false),
		"A caixa ainda não esconde o jogador antes de o carrinho chegar.")
	convoy.distance = convoy._distance_at_x(crate_edge + 15.0)
	convoy._place_trip(false)
	_check(vision.cover_at(refuge) == crate and not vision.can_see(refuge, false)
		and not vision.can_see(refuge, true) and vision.can_see(front, false),
		"Quando o carrinho chega, só o lado atrás da caixa protege o jogador.")
	var crate_art := crate.get_parent() as Sprite2D
	_check(crate_art.get_parent() == scene.player.get_parent() and crate_art.get_parent().y_sort_enabled
		and refuge.y < crate_art.global_position.y and front.y > crate_art.global_position.y,
		"A caixa tapa o jogador atrás e permite que passe visualmente à frente.")

	scene.player.global_position = front
	convoy._stopped_at_barrack = true
	convoy._start_trip(false)
	convoy.set_physics_process(true)
	var departure := convoy.cart.global_position
	scene._begin_pursuit(scene.guard_chase)
	await _ticks(72)
	_check(scene.guard_chase.art.animation == &"run" and not convoy.guard.visible
		and convoy.worker.is_playing() and convoy.cart.wheels.is_playing()
		and convoy.cart.global_position.distance_to(departure) > 45.0,
		"O prisioneiro e o carrinho continuam a animação e o percurso durante a corrida do guarda.")
	scene.player.global_position = refuge
	await _ticks(1)
	_check(scene.pursuer == null and scene.guard_returning and not scene.caught,
		"Entrar na cobertura da caixa interrompe a perseguição do guarda.")
	await _ticks(108)
	_check(not scene.guard_returning and not convoy.guard_detached and not scene.guard_chase.visible,
		"O guarda volta ao percurso em movimento após perder o jogador de vista.")
	scene.player.global_position = scene.arrival.global_position


func _ticks(count: int) -> void:
	for tick in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
