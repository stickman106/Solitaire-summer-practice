extends Control

@onready var scores_container = $VBoxContainer/ScoreList


func _ready():
	populate_leaderboard()
	ScoreManager.scores_updated.connect(populate_leaderboard)

func populate_leaderboard():
	# Очищаем предыдущие записи
	for child in scores_container.get_children():
		child.queue_free()
	
	var scores = ScoreManager.scores
	if scores.is_empty():
		var label = Label.new()
		label.text = "Пока нет рекордов"
		scores_container.add_child(label)
		return
	
	for i in range(scores.size()):
		var entry = scores[i]
		var line = Label.new()
		line.text = "%d. %s — %d ходов" % [i+1, entry["name"], entry["moves"]]
		scores_container.add_child(line)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
