extends Node2D

const OUTSIDE := preload("res://scenes/rooms/parte_de_fora.tscn")
const SLIDE_DURATION := 1.10

@onready var room: Node2D = $Room01
@onready var slide: ColorRect = $ExteriorTransition/Slide
@onready var slide_buffer: BackBufferCopy = $ExteriorTransition/SlideBuffer
@onready var slide_material: ShaderMaterial = slide.material

var transitioning := false


func _ready() -> void:
	var exit_area: Area2D = room.get_node("ExitToOutside")
	exit_area.body_entered.connect(_on_exit_body_entered)


func _on_exit_body_entered(body: Node2D) -> void:
	if transitioning or body != room.get_node("Characters/Player"):
		return
	transitioning = true
	body.set_physics_process(false)
	_enter_exterior.call_deferred()


func _enter_exterior() -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		slide_material.set_shader_parameter(&"outgoing", ImageTexture.create_from_image(frame))
		slide_material.set_shader_parameter(&"progress", 0.0)
		slide_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		slide.show()

	remove_child(room)
	room.queue_free()
	var exterior := OUTSIDE.instantiate()
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


func _enter_kitchen(exterior: Node2D) -> void:
	var kitchen := load(exterior.KITCHEN_SCENE) as PackedScene
	remove_child(exterior)
	exterior.queue_free()
	add_child(kitchen.instantiate())
