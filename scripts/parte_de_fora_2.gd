extends Node2D

@onready var player: CharacterBody2D = $Objetos/Player
@onready var arrival: Marker2D = $Chegada
@onready var arrival_fade: ColorRect = $Avisos/Transicao


func _ready() -> void:
	player.global_position = arrival.global_position
	create_tween().tween_property(arrival_fade, "color:a", 0.0, 0.35)
