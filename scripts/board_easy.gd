# board_easy.gd
# Extends board_base.gd to provide easier movement rules and win condition.
# Any flipped card can be placed on any other flipped card or on an empty pile.
# The game is won when all real cards are in one pile and the stock is empty.

extends "res://scripts/board_base.gd"

# Override the virtual methods from board_base
func is_valid_move(card: Area2D, target_card: Area2D) -> bool:
	# Cannot move to the same pile
	if target_card.pile_id == null or target_card.pile_id == card.pile_id:
		return false
	
	# Check if the target is an empty pile (the placeholder card)
	var pile = GameManager.piles[target_card.pile_id]
	if len(pile) == 1 and target_card.suit == -1 and target_card.value == -1:
		return true
	
	# Otherwise, the target must be flipped (open card)
	if not target_card.flipped:
		return false
	
	# In easy mode: any card on any open card is allowed
	return true

func check_win() -> bool:
	# Win condition: no cards left in stock and only one pile contains real cards
	if not GameManager.deck.is_empty():
		return false
	
	var non_empty_piles = 0
	for pile in GameManager.piles:
		# Pile size > 1 means it contains at least one real card (the placeholder is at index 0)
		if pile.size() > 1:
			non_empty_piles += 1
	
	if non_empty_piles == 1:
		win_game()
		return true
	return false

# Reuse the same initialisation as Klondike (same layout)
func init_game():
	clear_cards()
	clear_game_state()
	init_deck()
	deal_cards()
	place_stock_pile()
	moves = 0
	update_ui()

# ------------------------------------------------------------------------------
# Layout methods (copied and adapted from board_klondike.gd)
# ------------------------------------------------------------------------------

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
				card.flip()   # top card of each pile is face up
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
