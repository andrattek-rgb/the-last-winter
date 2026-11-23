class_name KitchenInteraction
extends CanvasLayer

signal served(food: StringName)

enum State { IDLE_CHOICE, SERVING_BREAD, SERVING_SOUP, FINISHED }

@export var idle_video: VideoStream
@export var bread_video: VideoStream
@export var soup_video: VideoStream
@export var idle_audio: AudioStream
@export var bread_audio: AudioStream
@export var soup_audio: AudioStream

@onready var video: VideoStreamPlayer = $Quadro/Enquadramento/Video
@onready var choices: HBoxContainer = $Quadro/Escolhas
@onready var bread_button: Button = $Quadro/Escolhas/Pao
@onready var soup_button: Button = $Quadro/Escolhas/Sopa
@onready var audio: AudioStreamPlayer = $Som

var state := State.FINISHED


func _ready() -> void:
	bread_button.pressed.connect(choose_bread)
	soup_button.pressed.connect(choose_soup)
	video.finished.connect(_on_video_finished)


func start() -> bool:
	if state != State.FINISHED or idle_video == null or bread_video == null or soup_video == null:
		return false
	state = State.IDLE_CHOICE
	show()
	choices.show()
	bread_button.grab_focus()
	_play(idle_video, idle_audio)
	return true


func choose_bread() -> void:
	_choose(State.SERVING_BREAD, bread_video, bread_audio)


func choose_soup() -> void:
	_choose(State.SERVING_SOUP, soup_video, soup_audio)


func _choose(next: State, stream: VideoStream, soundtrack: AudioStream) -> void:
	if state != State.IDLE_CHOICE:
		return
	state = next
	choices.hide()
	_play(stream, soundtrack)


func _play(stream: VideoStream, soundtrack: AudioStream) -> void:
	video.stop()
	audio.stop()
	video.stream = stream
	video.play()
	audio.stream = soundtrack
	if soundtrack != null:
		audio.play()


func _on_video_finished() -> void:
	if state == State.IDLE_CHOICE:
		_play(idle_video, idle_audio)
		return
	if state != State.SERVING_BREAD and state != State.SERVING_SOUP:
		return
	var food := &"pao" if state == State.SERVING_BREAD else &"sopa"
	audio.stop()
	state = State.FINISHED
	hide()
	served.emit(food)
