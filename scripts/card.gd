extends Area2D

var value = 0
var suit = 0
var flipped:bool = false
var is_dragging:bool = false

var pile_id = null
var stock:bool = false
var is_mouse_entered:bool = false
var previous_positions = []      # список { "position": Vector2, "z_index": int }
var dragged_group = []           # карты, которые перетаскиваются

@onready var sprite:Sprite2D = $Sprite2D

func _ready():
	update_sprite()

# --------------------------------------------
#  возвращает список карт для перетаскивания, если текущая карта является "разрешённой"
#
# Если карта не подходит, возвращается пустой массив.
# --------------------------------------------
func get_valid_drag_group():
	if pile_id == null:
		# карта из стока – всегда разрешена (одна карта)
		return [self]
	
	var pile = GameManager.piles[pile_id]
	if pile.size() <= 1:
		return []
	
	# Собираем все РЕАЛЬНЫЕ открытые карты в стопке (исключая пустышку и закрытые)
	var open_cards = []
	for card in pile:
		if card.value >= 0 and card.flipped:   # реальная карта и открыта
			open_cards.append(card)
	
	if open_cards.is_empty():
		return []
	
	var top_open = open_cards[-1]          # верхняя открытая
	var bottom_open = open_cards[0]        # нижняя открытая
	
	# Если текущая карта - верхняя открытая
	if self == top_open:
		return [self]      # переносим только одну карту
	
	# Если текущая карта - нижняя открытая (и при этом открытых карт больше одной)
	if self == bottom_open and open_cards.size() > 1:
		return open_cards.duplicate()   # переносим все открытые карты
	
	# Во всех остальных случаях (клик по середине группы открытых) - запрещено
	return []

# --------------------------------------------
# _input с проверкой разрешённой карты
# --------------------------------------------
func _input(event):
	if not is_mouse_entered or (suit == -1 and value == -1):
		return
		
	if Input.is_action_just_pressed("left_click") and stock:
		if GameManager.deck.is_empty():
			return
		update_stock_top()
		return
	
	if Input.is_action_just_pressed("left_click") and flipped:
		# проверяем, можно ли перетаскивать эту карту
		var drag_group = get_valid_drag_group()
		if drag_group.is_empty():
			return   # запрещено перетаскивание
		is_dragging = true
		remember_card_positions(drag_group)
	elif event is InputEventMouseMotion and is_dragging:
		move_cards()
	elif Input.is_action_just_released("left_click") and is_dragging:
		is_dragging = false
		if !drop_card():
			reset_cards()
		dragged_group.clear()

func _get_board():
	return get_tree().get_first_node_in_group("board")
		
func update_sprite():
	if sprite:
		sprite.texture = get_texture()
		if suit == -1 and value == -1:
			sprite.hide()
		
func get_texture():
	if not flipped or (suit == -1 and value == -1):
		return preload("res://card_assets/Back1.png")
	var res_path = "res://card_assets/{value}.{suit}.png".format({
		"value": str(value + 1),
		"suit": str(suit + 1)
	})
	return load(res_path)
	
func flip():
	flipped = !flipped
	update_sprite()

func can_move_to(target_card):
	var board = get_tree().get_first_node_in_group("board")
	if board:
		return board.is_valid_move(self, target_card)
	return false

# --------------------------------------------
# Перемещение в новую стопку (адаптировано под dragged_group)
# --------------------------------------------
func move_to_new_pile(new_card):
	if pile_id != null:
		var current_pile = GameManager.piles[pile_id]
		var new_pile = GameManager.piles[new_card.pile_id]
		
		var cards_to_move = dragged_group.duplicate()   # используем уже сохранённую группу
		if cards_to_move.is_empty():
			return
		
		var base_z = new_pile[-1].z_index if new_pile.size() > 0 else 0
		for i in range(len(cards_to_move)):
			var card = cards_to_move[i]
			card.position = GameManager.get_pile_position(
				new_card.pile_id, len(new_pile) - 1,
				GameManager.PILE_X_OFFSET, GameManager.PILE_Y_OFFSET
			)
			card.z_index = base_z + i + 1
			card.pile_id = new_card.pile_id
			new_pile.append(card)
		
		# Удаляем перемещённые карты из старой стопки (они находятся в конце)
		for i in range(len(cards_to_move)):
			current_pile.pop_back()
		
		# Если в старой стопке остались реальные карты, переворачиваем верхнюю
		if current_pile.size() > 1:
			var top_card = current_pile.back()
			if not top_card.flipped:
				top_card.flip()
	
	elif pile_id == null:
		# Перемещение из стока (без изменений)
		if GameManager.deck.is_empty():
			return
		var new_pile = GameManager.piles[new_card.pile_id]
		var card = GameManager.deck.pop_back()
		card.stock = false
		card.position = GameManager.get_pile_position(
			new_card.pile_id, len(new_pile) - 1,
			GameManager.PILE_X_OFFSET, GameManager.PILE_Y_OFFSET
		)
		card.z_index = new_pile[-1].z_index + 1 if new_pile.size() > 0 else 0
		card.pile_id = new_card.pile_id
		new_pile.append(card)
		
		if not GameManager.deck.is_empty():
			var card_on_stock = GameManager.deck[-1]
			card_on_stock.stock = false
			card_on_stock.flip()
			card_on_stock.position = GameManager.get_pile_position(
				0, 0, GameManager.PILE_X_OFFSET - 200, GameManager.PILE_Y_OFFSET + 200
			)
		
		var board = get_tree().get_first_node_in_group("board")
		if board:
			board.update_stock_count()
	
	previous_positions = []
	dragged_group.clear()
	get_tree().get_first_node_in_group("board").increment_moves()
	if get_tree().get_first_node_in_group("board").check_win():
		print("YOU WON!!")

# --------------------------------------------
# Логика стока (без изменений)
# --------------------------------------------
func update_stock_top():
	if GameManager.deck.is_empty():
		return
	var cur_stock_top = GameManager.deck.pop_back()
	cur_stock_top.flip()
	cur_stock_top.stock = true
	var old_position = cur_stock_top.position
	
	if GameManager.deck.is_empty():
		cur_stock_top.stock = false
		cur_stock_top.position = GameManager.get_pile_position(
			0, 0, GameManager.PILE_X_OFFSET - 200, GameManager.PILE_Y_OFFSET + 200
		)
		var board = get_tree().get_first_node_in_group("board")
		if board:
			board.update_stock_count()
		return
	
	cur_stock_top.position = GameManager.deck[0].position
	GameManager.deck.insert(0, cur_stock_top)
	
	if len(GameManager.deck) > 1:
		var new_card = GameManager.deck[-1]
		new_card.stock = false
		new_card.flip()
		new_card.position = old_position
	
	var board = get_tree().get_first_node_in_group("board")
	if board:
		board.update_stock_count()

# --------------------------------------------
# Визуальное перетаскивание
# --------------------------------------------
func move_cards():
	if pile_id == null:
		position = get_global_mouse_position()
		z_index = 100
		return
	
	if dragged_group.is_empty():
		return
	
	var mouse_pos = get_global_mouse_position()
	for i in range(len(dragged_group)):
		var card = dragged_group[i]
		card.position = mouse_pos
		card.position.y += 30 * i
		card.z_index = 100 + i

func drop_card():
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("card"):
			if can_move_to(area):
				move_to_new_pile(area)
				return true
	return false

func remember_card_positions(drag_group):
	previous_positions = []
	dragged_group = drag_group.duplicate()
	
	if pile_id == null:
		previous_positions.append({
			"position": position,
			"z_index": z_index
		})
		z_index = 100
		return
	
	for card in dragged_group:
		previous_positions.append({
			"position": card.position,
			"z_index": card.z_index
		})

func reset_cards():
	if pile_id == null:
		if previous_positions.size() > 0:
			position = previous_positions[0]['position']
			z_index = previous_positions[0]['z_index']
	else:
		for i in range(len(dragged_group)):
			var card = dragged_group[i]
			if i < previous_positions.size():
				card.position = previous_positions[i]['position']
				card.z_index = previous_positions[i]['z_index']
	previous_positions = []

func _on_mouse_entered():
	is_mouse_entered = true

func _on_mouse_exited():
	is_mouse_entered = false
