extends Node2D

const OUTSIDE_PATH := "res://scenes/rooms/parte_de_fora.tscn"
const OUTSIDE_PRELOAD_DISTANCE := 480.0
const SLIDE_DURATION := 1.10

@onready var room: Node2D = $Room01
@onready var exit_area: Area2D = room.get_node("ExitToOutside")
@onready var inside_player: CharacterBody2D = room.get_node("Characters/Player")
@onready var slide: ColorRect = $ExteriorTransition/Slide
@onready var slide_buffer: BackBufferCopy = $ExteriorTransition/SlideBuffer
@onready var slide_material: ShaderMaterial = slide.material

var transitioning := false
var loading_outside := false


func _ready() -> void:
	exit_area.body_entered.connect(_on_exit_body_entered)
	set_process(DisplayServer.get_name() != "headless" and not OS.has_feature("web"))


func _process(_delta: float) -> void:
	if inside_player.global_position.distance_to(exit_area.global_position) <= OUTSIDE_PRELOAD_DISTANCE:
		_request_outside()
		set_process(false)


func _request_outside() -> void:
	if not loading_outside and DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		loading_outside = ResourceLoader.load_threaded_request(OUTSIDE_PATH, "PackedScene") == OK


func _on_exit_body_entered(body: Node2D) -> void:
	if transitioning or body != inside_player:
		return
	transitioning = true
	set_process(false)
	body.set_physics_process(false)
	_enter_exterior.call_deferred()


func _enter_exterior() -> void:
	_request_outside()
	var outside_scene: PackedScene
	if loading_outside:
		while ResourceLoader.load_threaded_get_status(OUTSIDE_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		outside_scene = ResourceLoader.load_threaded_get(OUTSIDE_PATH) as PackedScene
		loading_outside = false
	else:
		outside_scene = ResourceLoader.load(OUTSIDE_PATH, "PackedScene") as PackedScene
	if outside_scene == null:
		push_error("Não foi possível carregar o exterior.")
		inside_player.set_physics_process(true)
		transitioning = false
		return

	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		slide_material.set_shader_parameter(&"outgoing", ImageTexture.create_from_image(frame))
		slide_material.set_shader_parameter(&"progress", 0.0)
		slide_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		slide.show()

	remove_child(room)
	room.queue_free()
	var exterior := outside_scene.instantiate()
	add_child(exterior)
	exterior.kitchen_requested.connect(_enter_kitchen.bind(exterior), CONNECT_ONE_SHOT)
	var player := exterior.get_node("Personagens/Player")
	if slide.visible:
		player.set_physics_process(false)
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(slide_material, "shader_parameter/progress", 1.0, SLIDE_DURATION)
		await tween.finished
		slide.hide()
		slide_buffer.copy_mode = BackBufferCopy.COPY_MODE_DISABLED
		slide_material.set_shader_parameter(&"outgoing", null)
		player.set_physics_process(true)


func _enter_kitchen(kitchen: PackedScene, exterior: Node2D) -> void:
	var kitchen_room := kitchen.instantiate()
	kitchen_room.outside_requested.connect(_enter_outside_2.bind(kitchen_room), CONNECT_ONE_SHOT)
	remove_child(exterior)
	exterior.queue_free()
	add_child(kitchen_room)


func _enter_outside_2(exterior: PackedScene, kitchen_room: Node2D) -> void:
	remove_child(kitchen_room)
	kitchen_room.queue_free()
	add_child(exterior.instantiate())
