extends Control

@onready var record_label = $RecordLabel

func _ready():
	update_record_display()
	ScoreManager.scores_updated.connect(update_record_display)

func update_record_display():
	if ScoreManager.best_score == INF:
		record_label.text = "Рекорд: —"
	else:
		record_label.text = "Рекорд: " + str(ScoreManager.best_score) + " ходов"


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Choice.tscn")


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")
