extends Node

signal scores_updated

const SAVE_PATH = "user://leaderboard.dat"
const MAX_SCORES = 10

var best_score = INF   # наименьшее количество ходов
var scores = []        # массив словарей { "name": String, "moves": int }

func _ready():
	load_scores()

# Добавление нового результата, если он попадает в топ
func add_score(name: String, moves: int):
	var new_entry = { "name": name, "moves": moves }
	scores.append(new_entry)
	
	# сортировка по возрастанию ходов
	scores.sort_custom(func(a, b): return a["moves"] < b["moves"])
	
	# оставляем только MAX_SCORES лучших
	if scores.size() > MAX_SCORES:
		scores = scores.slice(0, MAX_SCORES)
	
	# обновляем рекорд
	if moves < best_score:
		best_score = moves
	
	save_scores()
	scores_updated.emit()

# Проверка, попадает ли результат в таблицу
func is_highscore(moves: int) -> bool:
	if scores.size() < MAX_SCORES:
		return true
	return moves < scores[-1]["moves"]

func save_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = { "best_score": best_score, "scores": scores }
		var json = JSON.stringify(data)
		file.store_string(json)
		print("Сохранено: ", json)   # <- добавить
		file.close()
	else:
		print("Ошибка сохранения! Путь: ", SAVE_PATH)

func load_scores():
	if not FileAccess.file_exists(SAVE_PATH):
		print("Файл рекордов не найден, создаём новый")
		best_score = INF
		scores = []
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	print("Загружено из файла: ", content)   # <- добавить
	var data = JSON.parse_string(content)
	if data:
		best_score = data.get("best_score", INF)
		scores = data.get("scores", [])
	else:
		print("Ошибка парсинга JSON")
