class_name KitchenCauldron
extends StaticBody2D

@onready var station: Marker2D = $PontoDeParagem
@onready var aisle: Marker2D = $PontoDoCorredor
@onready var stove: AnimatedSprite2D = $Fogao
@onready var stirring: AnimatedSprite2D = $ComCozinheiro


func set_stirring(active: bool) -> void:
	stove.visible = not active
	stirring.visible = active
	if active:
		stirring.play(&"mexer")
	else:
		stirring.stop()
