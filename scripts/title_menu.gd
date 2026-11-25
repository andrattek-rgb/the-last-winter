extends Control

const GAME := preload("res://scenes/main.tscn")
const CHECKPOINTS := ["Barracks", "First courtyard", "Kitchen", "Second courtyard"]
const STORIES := [
	["Anne Frank", "Anne Frank was a Jewish teenager who went into hiding with her family in Amsterdam in 1942. In the Secret Annex, she wrote about daily life, her relationships, and her hopes of becoming a writer. She and her sister Margot died in Bergen-Belsen. Their father, Otto, survived and arranged for Anne's diary to be published.", "Anne Frank House", "https://www.annefrank.org/en/anne-frank/who-was-anne-frank/"],
	["Elie Wiesel", "Elie Wiesel was fifteen when he and his family were deported from Sighet to Auschwitz-Birkenau in 1944. He was forced to work at Monowitz and was later imprisoned at Buchenwald. He survived and wrote Night about his experiences. He went on to teach, speak about the Holocaust, and advocate for human rights.", "United States Holocaust Memorial Museum", "https://encyclopedia.ushmm.org/content/en/article/elie-wiesel"],
	["Gerda Weissmann Klein", "Gerda Weissmann Klein was a Jewish teenager from Bielsko, Poland. She was separated from her family and sent to forced labor camps. She survived a death march and was liberated in Czechoslovakia in May 1945. She later recorded her experiences in a memoir, All But My Life.", "United States Holocaust Memorial Museum", "https://encyclopedia.ushmm.org/content/en/id-card/gerda-weissmann"],
	["Janusz Korczak", "Janusz Korczak, born Henryk Goldszmit, was a Polish Jewish doctor, writer, and educator. He directed a Jewish orphanage in Warsaw and continued to care for its children inside the ghetto. In August 1942, he and fellow staff member Stefania Wilczyńska accompanied the children when they were deported to Treblinka, where they were murdered.", "United States Holocaust Memorial Museum", "https://encyclopedia.ushmm.org/content/en/article/janusz-korczak-1"],
	["Irena Sendler", "Irena Sendler worked as a social worker in Warsaw. As part of the underground aid network Żegota, she helped Jewish children escape the Warsaw ghetto and find places to hide. The Gestapo arrested her in 1943. After her release, she continued her rescue work in hiding and survived the war.", "United States Holocaust Memorial Museum", "https://encyclopedia.ushmm.org/content/en/oral-history/irena-sendler-describes-how-she-was-arrested-and-tortured-by-the-gestapo"],
]

@onready var actions: VBoxContainer = $Actions
@onready var new_game: Button = $Actions/NewGame
@onready var continue_game: Button = $Actions/Continue
@onready var slots: Control = $Slots
@onready var cards: VBoxContainer = $Slots/Content/Cards
@onready var original: Button = $Slots/Content/Original
@onready var credits: Control = $Credits
@onready var story_title: Label = $Credits/Content/Title
@onready var story_body: Label = $Credits/Content/Story
@onready var source: Button = $Credits/Content/Source
@onready var previous_page: Button = $Credits/Content/Navigation/Previous
@onready var next_page: Button = $Credits/Content/Navigation/Next
@onready var disclaimer: Control = $Disclaimer

var bridge: JavaScriptObject
var save_path := "user://title_progress.cfg"
var saves := ConfigFile.new()
var primary_checkpoint := -1
var selected_slot := 0
var selected_checkpoint := 0
var page := 0
var restarting := false


func _ready() -> void:
	if OS.has_feature("web"):
		bridge = JavaScriptBridge.get_interface("winterProgress")
		if bridge != null:
			save_path = "user://title_progress_%s.cfg" % str(bridge.accountId).sha256_text()
			if bool(bridge.hasProgress):
				primary_checkpoint = int(bridge.startingCheckpoint)
	saves.load(save_path)
	if bridge == null:
		primary_checkpoint = _saved_checkpoint(0)
	_refresh_home()


func _saved_checkpoint(slot: int) -> int:
	var checkpoint := int(saves.get_value("checkpoints", str(slot), -1))
	return checkpoint if checkpoint >= 0 and checkpoint < CHECKPOINTS.size() else -1


func _refresh_home() -> void:
	actions.show()
	continue_game.visible = primary_checkpoint >= 0 or range(1, 4).any(
		func(slot: int) -> bool: return _saved_checkpoint(slot) >= 0)
	new_game.grab_focus()


func _new_game() -> void:
	if primary_checkpoint < 0:
		_show_disclaimer(0, 0)
	else:
		_show_slots(true)


func _show_slots(start_new: bool = false) -> void:
	restarting = start_new
	actions.hide()
	slots.show()
	$Slots/Content/Title.text = "NEW GAME" if start_new else "CONTINUE"
	original.visible = not start_new and primary_checkpoint >= 0
	if original.visible:
		original.text = "Original save   ·   %s" % CHECKPOINTS[primary_checkpoint]
	for index in cards.get_child_count():
		var checkpoint := _saved_checkpoint(index + 1)
		var detail: String = "Empty" if checkpoint < 0 else CHECKPOINTS[checkpoint]
		cards.get_child(index).text = "SLOT %02d   ·   %s" % [index + 1, detail]
	if original.visible:
		original.grab_focus()
	else:
		cards.get_child(0).grab_focus()


func _choose_slot(slot: int) -> void:
	var checkpoint := _saved_checkpoint(slot)
	if restarting and checkpoint >= 0:
		$ReplaceDialog.dialog_text = "Restart Slot %02d from the beginning? Its current progress will be replaced." % slot
		$ReplaceDialog.popup_centered()
		selected_slot = slot
		return
	_show_disclaimer(slot, maxi(0, checkpoint))


func _restart_selected_slot() -> void:
	_show_disclaimer(selected_slot, 0)


func _resume_original() -> void:
	_show_disclaimer(0, primary_checkpoint)


func _show_disclaimer(slot: int, checkpoint: int) -> void:
	selected_slot = slot
	selected_checkpoint = checkpoint
	actions.hide()
	slots.hide()
	disclaimer.show()
	$Disclaimer/Content/Proceed.grab_focus()


func _start_game() -> void:
	var game := GAME.instantiate()
	game.configure_start(selected_checkpoint, selected_slot, save_path)
	var tree := get_tree()
	hide()
	tree.root.add_child(game)
	tree.current_scene = game
	queue_free()


func _show_credits() -> void:
	actions.hide()
	credits.show()
	page = 0
	_render_page()
	next_page.grab_focus()


func _render_page() -> void:
	var last := page == STORIES.size()
	story_title.text = "By: Michel Chaves Andrade" if last else STORIES[page][0]
	story_body.text = "" if last else STORIES[page][1]
	story_body.visible = not last
	source.visible = not last
	source.text = "" if last else STORIES[page][2]
	$Credits/Content/Navigation/Count.text = "%d / %d" % [page + 1, STORIES.size() + 1]
	previous_page.disabled = page == 0
	next_page.disabled = last


func _turn_page(direction: int) -> void:
	page = clampi(page + direction, 0, STORIES.size())
	_render_page()
	if next_page.disabled:
		previous_page.grab_focus()
	elif previous_page.disabled:
		next_page.grab_focus()


func _open_source() -> void:
	if page < STORIES.size():
		OS.shell_open(STORIES[page][3])


func _back_home() -> void:
	slots.hide()
	credits.hide()
	_refresh_home()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if disclaimer.visible:
			disclaimer.hide()
			_refresh_home()
		elif slots.visible or credits.visible:
			_back_home()
		else:
			return
		get_viewport().set_input_as_handled()


func _quit() -> void:
	if bridge != null:
		bridge.quitToPortal()
	else:
		get_tree().quit()
