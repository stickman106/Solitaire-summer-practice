extends "res://scripts/board_base.gd"

func init_game():
	clear_cards()
	clear_game_state()
	init_deck()
	deal_cards()
	place_stock_pile()
	moves = 0
	update_ui()

func deal_cards():
	for i in range(GameManager.NO_OF_PILES):
		var pile = GameManager.piles[i]
		var empty_card = get_empty_card()
		empty_card.pile_id = i
		empty_card.position = GameManager.get_pile_position(i, 0, GameManager.PILE_X_OFFSET, GameManager.PILE_Y_OFFSET)
		pile.append(empty_card)
		add_child(empty_card)
		for j in range(0, i + 1):
			var card = GameManager.deck.pop_back()
			card.z_index = j
			if j == i:
				card.flip()
			card.position = GameManager.get_pile_position(i, j, GameManager.PILE_X_OFFSET, GameManager.PILE_Y_OFFSET)
			card.pile_id = i
			pile.append(card)
			add_child(card)

func place_stock_pile():
	for i in range(len(GameManager.deck) - 1):
		var card = GameManager.deck[i]
		card.stock = true
		card.position = GameManager.get_pile_position(0, 0, GameManager.PILE_X_OFFSET - 200, GameManager.PILE_Y_OFFSET)
		add_child(card)
	var last_card = GameManager.deck[-1]
	last_card.stock = false
	last_card.flip()
	last_card.position = GameManager.get_pile_position(0, 0, GameManager.PILE_X_OFFSET - 200, GameManager.PILE_Y_OFFSET + 200)
	add_child(last_card)
	update_stock_count()

func is_valid_move(card: Area2D, target_card: Area2D) -> bool:
	if target_card.pile_id == null or target_card.pile_id == card.pile_id:
		return false
	var pile = GameManager.piles[target_card.pile_id]
	if len(pile) == 1 and target_card.suit == -1 and target_card.value == -1:
		return true
	if not target_card.flipped:
		return false
	if card.value == target_card.value - 1 and card.suit % 2 != target_card.suit % 2:
		return true
	return false

func check_win() -> bool:
	if len(GameManager.deck) > 0:
		return false
	for pile in GameManager.piles:
		for card in pile:
			if not card.flipped:
				return false
	win_game()
	return true

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W and event.ctrl_pressed and event.shift_pressed:
			force_win(false)

func force_win(record_score = true):
	GameManager.deck.clear()
	update_stock_count()
	for pile in GameManager.piles:
		for card in pile:
			if not card.flipped:
				card.flip()
	if record_score:
		if ScoreManager.is_highscore(moves):
			var name = await ask_for_name()
			if name != "":
				ScoreManager.add_score(name, moves)
		show_game_over_dialog()
	else:
		check_win()

func return_to_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
