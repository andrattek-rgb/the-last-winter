extends Node2D

@onready var player: CharacterBody2D = $EmCena/Player
@onready var area: Area2D = $EmCena/Balcao/Interacao
@onready var prompt: Label = $Avisos/Interagir
@onready var interaction: KitchenInteraction = $KitchenInteraction
@onready var arrival_fade: ColorRect = $Avisos/Chegada

var received_food: Array[StringName] = []


func _ready() -> void:
	player.global_position = $PlayerSpawn.global_position
	area.body_entered.connect(_on_range_changed)
	area.body_exited.connect(_on_range_changed)
	interaction.served.connect(_on_food_served)
	create_tween().tween_property(arrival_fade, "color:a", 0.0, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and area.overlaps_body(player) and interaction.start():
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
		player.get_node("Sprite").play(&"idle")
		prompt.hide()
		get_viewport().set_input_as_handled()


func _on_range_changed(body: Node2D) -> void:
	if body == player:
		_refresh_prompt.call_deferred()


func _refresh_prompt() -> void:
	prompt.visible = interaction.state == KitchenInteraction.State.FINISHED and area.overlaps_body(player)


func _on_food_served(food: StringName) -> void:
	received_food.append(food)
	player.set_physics_process(true)
	_refresh_prompt()
