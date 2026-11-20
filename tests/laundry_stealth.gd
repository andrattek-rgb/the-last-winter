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
	scene.set_physics_process(true)
	await _ticks(43)
	_check(scene.get("caught"), "A exposição contínua deteta o jogador.")
	await _ticks(65)
	_check(not scene.get("caught") and player.global_position.distance_to(Vector2(255, 765)) < 2.0,
		"Uma deteção permite recomeçar junto ao primeiro barracão.")

	convoy._physics_process(convoy.load_seconds + approach_seconds + convoy.idle_seconds + convoy.stop_seconds
		+ route_length / convoy.pull_speed * 0.88)
	convoy.set_physics_process(true)
	Input.action_press(&"move_forward")
	await _ticks(36)
	Input.action_release(&"move_forward")
	Input.action_press(&"move_right")
	for tick in range(380):
		await physics_frame
		if player.global_position.x >= 1600.0:
			break
	Input.action_release(&"move_right")
	Input.action_press(&"move_back")
	await _ticks(100)
	Input.action_release(&"move_back")
	_check(scene.get("entering") and not player.visible,
		"É possível aproveitar a passagem do conjunto para alcançar a porta sem deteção.")

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


func _ticks(count: int) -> void:
	for tick in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
