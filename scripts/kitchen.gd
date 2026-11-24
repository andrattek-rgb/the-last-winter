extends Node2D

signal outside_requested(scene: PackedScene)

const OUTSIDE_PATH := "res://scenes/rooms/parte_de_fora_2.tscn"

@onready var player: CharacterBody2D = $EmCena/Player
@onready var area: Area2D = $EmCena/Balcao/Interacao
@onready var exit_area: Area2D = $SaidaParaExterior
@onready var prompt: Label = $Avisos/Interagir
@onready var interaction: KitchenInteraction = $KitchenInteraction
@onready var arrival_fade: ColorRect = $Avisos/Chegada

var received_food: Array[StringName] = []
var leaving := false


func _ready() -> void:
	player.global_position = $PlayerSpawn.global_position
	area.body_entered.connect(_on_range_changed)
	area.body_exited.connect(_on_range_changed)
	interaction.served.connect(_on_food_served)
	create_tween().tween_property(arrival_fade, "color:a", 0.0, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if leaving:
		return
	if event.is_action_pressed(&"interact") and area.overlaps_body(player) and interaction.start():
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
		player.get_node("Sprite").play(&"idle")
		prompt.hide()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not leaving and interaction.state == KitchenInteraction.State.FINISHED \
		and Input.is_action_pressed(&"move_right") and exit_area.overlaps_body(player):
		_leave()


func _leave() -> void:
	leaving = true
	prompt.hide()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	player.get_node("Sprite").play(&"idle")
	var loading := false
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		loading = ResourceLoader.load_threaded_request(OUTSIDE_PATH, "PackedScene") == OK
	await create_tween().tween_property(arrival_fade, "color:a", 1.0, 0.35).finished
	var exterior: PackedScene
	if loading:
		while ResourceLoader.load_threaded_get_status(OUTSIDE_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		exterior = ResourceLoader.load_threaded_get(OUTSIDE_PATH) as PackedScene
	else:
		exterior = ResourceLoader.load(OUTSIDE_PATH, "PackedScene") as PackedScene
	if exterior == null:
		push_error("Não foi possível carregar a Parte de Fora 2.")
		create_tween().tween_property(arrival_fade, "color:a", 0.0, 0.35)
		player.set_physics_process(true)
		leaving = false
		return
	if get_tree().current_scene == self:
		get_tree().change_scene_to_packed(exterior)
	else:
		outside_requested.emit(exterior)


func _on_range_changed(body: Node2D) -> void:
	if body == player:
		_refresh_prompt.call_deferred()


func _refresh_prompt() -> void:
	prompt.visible = not leaving and interaction.state == KitchenInteraction.State.FINISHED and area.overlaps_body(player)


func _on_food_served(food: StringName) -> void:
	received_food.append(food)
	player.set_physics_process(true)
	_refresh_prompt()
