extends StaticBody2D

@export_range(0, 47) var start_frame := 0


func _ready() -> void:
	var sprite: AnimatedSprite2D = $Sprite
	sprite.play(&"comer")
	sprite.frame = start_frame
