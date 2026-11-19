extends Node2D

@onready var player: CharacterBody2D = $Personagens/Player
@onready var arrival: Marker2D = $ChegadaDoBarracao
@onready var camera: Camera2D = $CameraPrevisualizacao
@onready var entrance: Area2D = $EntradaPortaAberta
@onready var doorway: Marker2D = $EntradaPortaAberta/Limiar
@onready var entry_fade: ColorRect = $FimDoPercurso/Escurecimento

var entering := false


func _ready() -> void:
	player.global_position = arrival.global_position
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if entering or not player.is_physics_processing():
		return
	if Input.is_action_pressed(&"move_back") and entrance.overlaps_body(player):
		entering = true
		_walk_through_door()


func _walk_through_door() -> void:
	player.set_physics_process(false)
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	sprite.play(&"run")
	var entry := create_tween()
	entry.tween_property(player, "global_position", doorway.global_position, 0.48)
	entry.parallel().tween_property(entry_fade, "color:a", 1.0, 0.40).set_delay(0.20)
	await entry.finished
	sprite.stop()
	player.hide()
