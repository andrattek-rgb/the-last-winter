extends Node2D

enum Checkpoint { ROOM, OUTSIDE, KITCHEN, OUTSIDE_2 }

const CHECKPOINT_SCENES := {
	Checkpoint.ROOM: "res://scenes/rooms/room_01.tscn",
	Checkpoint.OUTSIDE: "res://scenes/rooms/parte_de_fora.tscn",
	Checkpoint.KITCHEN: "res://scenes/rooms/kitchen.tscn",
	Checkpoint.OUTSIDE_2: "res://scenes/rooms/parte_de_fora_2.tscn",
}
const OUTSIDE_PATH: String = CHECKPOINT_SCENES[Checkpoint.OUTSIDE]
const OUTSIDE_PRELOAD_DISTANCE := 480.0
const SLIDE_DURATION := 1.10

@onready var slide: ColorRect = $ExteriorTransition/Slide
@onready var slide_buffer: BackBufferCopy = $ExteriorTransition/SlideBuffer
@onready var slide_material: ShaderMaterial = slide.material

var transitioning := false
var loading_outside := false
var room: Node2D
var exit_area: Area2D
var inside_player: CharacterBody2D
var web_progress: JavaScriptObject
var starting_checkpoint := Checkpoint.ROOM
var save_slot := 0
var save_path := ""


func configure_start(checkpoint: int, slot: int, path: String) -> void:
	if CHECKPOINT_SCENES.has(checkpoint):
		starting_checkpoint = checkpoint as Checkpoint
	save_slot = slot
	save_path = path


func _ready() -> void:
	if OS.has_feature("web") and save_slot == 0:
		web_progress = JavaScriptBridge.get_interface("winterProgress")
	_mount_checkpoint(load(CHECKPOINT_SCENES[starting_checkpoint]) as PackedScene, starting_checkpoint)


func _mount_checkpoint(packed: PackedScene, checkpoint: Checkpoint) -> Node2D:
	var zone := packed.instantiate() as Node2D
	add_child(zone)
	set_process(false)
	match checkpoint:
		Checkpoint.ROOM:
			room = zone
			exit_area = room.get_node("ExitToOutside")
			inside_player = room.get_node("Characters/Player")
			exit_area.body_entered.connect(_on_exit_body_entered)
			set_process(DisplayServer.get_name() != "headless" and not OS.has_feature("web"))
		Checkpoint.OUTSIDE:
			zone.kitchen_requested.connect(_enter_kitchen.bind(zone), CONNECT_ONE_SHOT)
		Checkpoint.KITCHEN:
			zone.outside_requested.connect(_enter_outside_2.bind(zone), CONNECT_ONE_SHOT)
	if web_progress != null:
		web_progress.checkpointReached(int(checkpoint))
	elif not save_path.is_empty():
		var saves := ConfigFile.new()
		saves.load(save_path)
		saves.set_value("checkpoints", str(save_slot), int(checkpoint))
		if saves.save(save_path) != OK:
			push_warning("Could not save game slot %d." % save_slot)
	return zone


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
	var exterior := _mount_checkpoint(outside_scene, Checkpoint.OUTSIDE)
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
	remove_child(exterior)
	exterior.queue_free()
	_mount_checkpoint(kitchen, Checkpoint.KITCHEN)


func _enter_outside_2(exterior: PackedScene, kitchen_room: Node2D) -> void:
	remove_child(kitchen_room)
	kitchen_room.queue_free()
	_mount_checkpoint(exterior, Checkpoint.OUTSIDE_2)
