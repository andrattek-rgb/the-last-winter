extends Node2D

signal kitchen_requested

const KITCHEN_SCENE := "res://scenes/rooms/kitchen.tscn"

@onready var player: CharacterBody2D = $Personagens/Player
@onready var arrival: Marker2D = $ChegadaDoBarracao
@onready var camera: Camera2D = $CameraPrevisualizacao
@onready var entrance: Area2D = $EntradaPortaAberta
@onready var doorway: Marker2D = $EntradaPortaAberta/Limiar
@onready var entry_fade: ColorRect = $FimDoPercurso/Escurecimento
@onready var vision: GuardVision = $Desafio/VisaoDoGuarda
@onready var caught_notice: Label = $FimDoPercurso/AvisoDetecao
@onready var pile_art: Sprite2D = $Personagens/PilhaDePijamas/Pijamas

var entering := false
var caught := false


func _ready() -> void:
	player.global_position = arrival.global_position
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()


func _physics_process(delta: float) -> void:
	if entering or caught or not player.is_physics_processing():
		return
	var cover: StealthCover
	if player.crouched and vision.convoy.guard_is_exposed():
		cover = vision.cover_at(player.global_position)
	_show_cover(cover)
	if vision.update_exposure(delta, player.global_position, player.crouched):
		_restart_after_detection()
		return
	if Input.is_action_pressed(&"move_back") and entrance.overlaps_body(player):
		entering = true
		_walk_through_door()


func _restart_after_detection() -> void:
	caught = true
	_show_cover(null)
	player.set_physics_process(false)
	player.get_node("Sprite").play(&"idle")
	caught_notice.show()
	await get_tree().create_timer(0.85).timeout
	player.global_position = arrival.global_position
	player.velocity = Vector2.ZERO
	camera.global_position.x = player.global_position.x
	camera.reset_smoothing()
	vision.exposure = 0.0
	caught_notice.hide()
	caught = false
	player.set_physics_process(true)


func _walk_through_door() -> void:
	_show_cover(null)
	player.set_physics_process(false)
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	sprite.play(&"run")
	var entry := create_tween()
	entry.tween_property(player, "global_position", doorway.global_position, 0.48)
	entry.parallel().tween_property(entry_fade, "color:a", 1.0, 0.40).set_delay(0.20)
	await entry.finished
	sprite.stop()
	player.hide()
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(KITCHEN_SCENE)
	else:
		kitchen_requested.emit()


func _show_cover(cover: StealthCover) -> void:
	pile_art.z_index = 1 if cover == vision.convoy.pile else 0
