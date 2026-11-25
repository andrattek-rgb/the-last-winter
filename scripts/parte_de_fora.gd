extends Node2D

signal kitchen_requested(scene: PackedScene)

const KITCHEN_SCENE := "res://scenes/rooms/kitchen.tscn"

@export_range(0.0, 900.0) var dog_sight_range := 430.0
@export_range(0.1, 3.0) var dog_detection_seconds := 0.42
@export var dog_chase_ground_y := 751.0
@export var guard_chase_ground_y := 751.0

@onready var player: CharacterBody2D = $Personagens/Player
@onready var arrival: Marker2D = $ChegadaDoBarracao
@onready var camera: Camera2D = $CameraPrevisualizacao
@onready var entrance: Area2D = $EntradaPortaAberta
@onready var doorway: Marker2D = $EntradaPortaAberta/Limiar
@onready var entry_fade: ColorRect = $FimDoPercurso/Escurecimento
@onready var vision: GuardVision = $Desafio/VisaoDoGuarda
@onready var pile_art: Sprite2D = $Personagens/PilhaDePijamas/Pijamas
@onready var dog: YardPursuer = $Personagens/Cao
@onready var guard_chase: YardPursuer = $Personagens/GuardaEmPerseguicao
@onready var dog_home := dog.global_position

var entering := false
var caught := false
var dog_exposure := 0.0
var dog_returning := false
var guard_returning := false
var pursuer: YardPursuer
var resume_convoy := true


func _ready() -> void:
	guard_chase.hide()
	player.global_position = arrival.global_position
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	if entering or caught or not player.is_physics_processing():
		return
	if dog_returning:
		dog_returning = not dog.return_to(dog_home, dog_chase_ground_y, delta)
	if guard_returning:
		_return_guard_to_convoy(delta)
	if pursuer != null:
		if pursuer == guard_chase and vision.is_in_crate_cover(player.global_position):
			guard_chase.begin_return()
			guard_returning = true
			vision.exposure = 0.0
			pursuer = null
			return
		if pursuer == dog and vision.is_protected(dog.global_position, player.global_position, player.crouched):
			dog.begin_return()
			dog_returning = true
			dog_exposure = 0.0
			pursuer = null
			return
		if pursuer.advance(delta):
			_restart_after_capture()
		return
	var cover: StealthCover
	if player.crouched:
		cover = vision.cover_at(player.global_position)
	_show_cover(cover)
	if not guard_returning and vision.update_exposure(delta, player.global_position, player.crouched):
		_begin_pursuit(guard_chase)
		return
	dog_exposure = dog_exposure + delta if not guard_returning and _dog_can_see(player.global_position) else 0.0
	if dog_exposure >= dog_detection_seconds:
		_begin_pursuit(dog)
		return
	if Input.is_action_pressed(&"move_back") and entrance.overlaps_body(player):
		entering = true
		_walk_through_door()


func _dog_can_see(target: Vector2) -> bool:
	return (
		dog_sight_range > 0.0
		and not dog_returning
		and vision.convoy.guard_is_escorting()
		and target.x >= vision.sight_start_x
		and dog.global_position.distance_squared_to(target) < dog_sight_range * dog_sight_range
		and not vision.is_protected(dog.global_position, target, player.crouched)
	)


func _begin_pursuit(actor: YardPursuer) -> void:
	pursuer = actor
	resume_convoy = vision.convoy.is_physics_processing()
	if actor == guard_chase:
		var convoy := vision.convoy
		guard_chase.global_position = convoy.guard.global_position
		guard_chase.art.flip_h = convoy.guard.flip_h
		convoy.set_guard_detached(true)
		guard_chase.show()
		guard_chase.begin(player, guard_chase_ground_y)
	else:
		dog.begin(player, dog_chase_ground_y)


func _return_guard_to_convoy(delta: float) -> void:
	var convoy := vision.convoy
	if not guard_chase.return_to(convoy.guard.global_position, guard_chase_ground_y, delta):
		return
	guard_returning = false
	convoy.set_guard_detached(false)


func _restart_after_capture() -> void:
	caught = true
	_show_cover(null)
	vision.convoy.set_physics_process(false)
	player.set_physics_process(false)
	player.get_node("Sprite").play(&"idle")
	var fade_out := create_tween()
	fade_out.tween_property(entry_fade, "color:a", 1.0, 0.22)
	await fade_out.finished
	pursuer = null
	guard_chase.reset()
	guard_returning = false
	dog.global_position = dog_home
	dog.reset()
	dog_returning = false
	vision.convoy.restart_at_pile()
	player.global_position = arrival.global_position
	player.velocity = Vector2.ZERO
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()
	vision.exposure = 0.0
	dog_exposure = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(entry_fade, "color:a", 0.0, 0.28)
	await fade_in.finished
	vision.convoy.set_physics_process(resume_convoy)
	caught = false
	player.set_physics_process(true)


func _walk_through_door() -> void:
	_show_cover(null)
	player.set_physics_process(false)
	var loading_kitchen := false
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		loading_kitchen = ResourceLoader.load_threaded_request(KITCHEN_SCENE, "PackedScene") == OK
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	sprite.play(&"run")
	var entry := create_tween()
	entry.tween_property(player, "global_position", doorway.global_position, 0.48)
	entry.parallel().tween_property(entry_fade, "color:a", 1.0, 0.40).set_delay(0.20)
	await entry.finished
	var kitchen_scene: PackedScene
	if loading_kitchen:
		while ResourceLoader.load_threaded_get_status(KITCHEN_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		kitchen_scene = ResourceLoader.load_threaded_get(KITCHEN_SCENE) as PackedScene
	else:
		kitchen_scene = ResourceLoader.load(KITCHEN_SCENE, "PackedScene") as PackedScene
	if kitchen_scene == null:
		push_error("Não foi possível carregar a cozinha.")
		player.global_position = arrival.global_position
		entry_fade.color.a = 0.0
		player.set_physics_process(true)
		entering = false
		return

	sprite.stop()
	player.hide()
	if get_tree().current_scene == self:
		get_tree().change_scene_to_packed(kitchen_scene)
	else:
		kitchen_requested.emit(kitchen_scene)


func _show_cover(cover: StealthCover) -> void:
	pile_art.z_index = 1 if cover == vision.convoy.pile else 0
