extends Node2D

@onready var moves_label = $HUD/MovesLabel
@onready var best_label = $HUD/BestLabel
@onready var stock_count_label = $HUD/StockCountLabel

var moves = 0

func _ready():
	add_to_group("board")
	init_game()
	update_ui()
	if ScoreManager.best_score != INF:
		best_label.text = "Рекорд: " + str(ScoreManager.best_score)

# Виртуальные методы (переопределяются в наследниках)
func init_game():
	clear_game_state()

func is_valid_move(card: Area2D, target_card: Area2D) -> bool:
	return false

func check_win() -> bool:
	return false

# Общие методы
func init_deck():
	GameManager.deck.clear()
	for suit in range(4):
		for value in range(13):
			var card = preload("res://scenes/Card.tscn").instantiate()
			card.value = value
			card.suit = suit
			GameManager.deck.append(card)
	randomize()
	GameManager.deck.shuffle()

func update_stock_count():
	if stock_count_label:
		stock_count_label.text = "В стоке: " + str(GameManager.deck.size())

func get_empty_card():
	var card = preload("res://scenes/Card.tscn").instantiate()
	card.value = -1
	card.suit = -1
	card.flip()
	return card

func increment_moves():
	moves += 1
	update_ui()

func update_ui():
	if moves_label:
		moves_label.text = "Ходы: " + str(moves)
	if best_label and ScoreManager.best_score != INF:
		best_label.text = "Рекорд: " + str(ScoreManager.best_score)

func win_game():
	if ScoreManager.is_highscore(moves):
		var player_name = await ask_for_name()
		if player_name != "":
			ScoreManager.add_score(player_name, moves)
	show_game_over_dialog()

func ask_for_name() -> String:
	var popup = PopupPanel.new()
	popup.title = "Новый рекорд!"
	popup.size = Vector2(300, 150)
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1
	vbox.anchor_bottom = 1
	var label = Label.new()
	label.text = "Введите ваше имя:"
	vbox.add_child(label)
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Ваше имя"
	vbox.add_child(line_edit)
	var hbox = HBoxContainer.new()
	var ok_btn = Button.new()
	ok_btn.text = "Сохранить"
	var cancel_btn = Button.new()
	cancel_btn.text = "Отмена"
	hbox.add_child(ok_btn)
	hbox.add_child(cancel_btn)
	vbox.add_child(hbox)
	popup.add_child(vbox)
	add_child(popup)
	popup.popup_centered()
	await get_tree().process_frame
	line_edit.grab_focus()

	var result = ["Аноним"]
	ok_btn.pressed.connect(func():
		var text = line_edit.text.strip_edges()
		result[0] = text if text != "" else "Аноним"
		popup.queue_free()
	)
	cancel_btn.pressed.connect(func():
		result[0] = "Аноним"
		popup.queue_free()
	)
	popup.close_requested.connect(func():
		result[0] = "Аноним"
		popup.queue_free()
	)
	await popup.tree_exited
	return result[0]

func show_game_over_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Поздравляем!"
	dialog.dialog_text = "Вы собрали пасьянс за %d ходов!" % moves
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free()
	call_deferred("return_to_menu")

func clear_game_state():
	GameManager.deck.clear()
	GameManager.piles = []
	for i in range(GameManager.NO_OF_PILES):
		GameManager.piles.append([])

func clear_cards():
	for child in get_children():
		# Оставляем только HUD (или любой узел, который не является картой)
		if child.name != "HUD":
			child.queue_free()

func reset_game():
	init_game()

func _on_reset_button_pressed():
	reset_game()

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
