extends SceneTree

const MENU := preload("res://scenes/ui/title_menu.tscn")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var path := "user://title_menu_test_%d.cfg" % Time.get_ticks_usec()
	var menu := MENU.instantiate()
	menu.save_path = path
	root.add_child(menu)
	_check(not menu.get_node("Actions/Continue").visible, "Continue stays hidden before the first save.")
	menu.get_node("Actions/Credits").pressed.emit()
	for story in ["Anne Frank", "Elie Wiesel", "Gerda Weissmann Klein", "Janusz Korczak", "Irena Sendler"]:
		_check(menu.story_title.text == story and not menu.story_body.text.is_empty()
			and menu.source.visible, "A credits page is dedicated to %s." % story)
		menu.next_page.pressed.emit()
	_check(menu.story_title.text == "By: Michel Chaves Andrade" and menu.next_page.disabled,
		"The sixth page shows the author.")
	menu.get_node("Credits/Content/Back").pressed.emit()
	menu.get_node("Actions/NewGame").pressed.emit()
	_check(menu.disclaimer.visible and current_scene == null, "New Game opens the disclaimer before gameplay.")
	menu.get_node("Disclaimer/Content/Proceed").pressed.emit()
	_check(current_scene.has_node("Room01"), "Proceed starts the first room.")
	current_scene.queue_free()
	await process_frame

	menu = MENU.instantiate()
	menu.save_path = path
	root.add_child(menu)
	_check(menu.get_node("Actions/Continue").visible, "Continue appears after a save.")
	menu.get_node("Actions/Continue").pressed.emit()
	_check(menu.original.visible and menu.cards.get_child_count() == 3, "Continue shows the original save and exactly three cards.")
	for card in menu.cards.get_children():
		_check(card.text.ends_with("Empty"), "Additional slots start empty.")
	menu.cards.get_child(1).pressed.emit()
	_check(menu.disclaimer.visible and menu.selected_slot == 2, "An empty card starts an independent story.")
	menu.get_node("Disclaimer/Content/Proceed").pressed.emit()
	_check(current_scene.has_node("Room01"), "An empty card starts in the barracks.")
	var saves := ConfigFile.new()
	_check(saves.load(path) == OK and saves.get_value("checkpoints", "0", -1) == 0
		and saves.get_value("checkpoints", "2", -1) == 0
		and not saves.has_section_key("checkpoints", "1"), "Only the selected new slot is added.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Title menu: %d failures." % failures)
	quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
