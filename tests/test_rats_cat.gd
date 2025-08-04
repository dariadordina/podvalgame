extends Node3D

@onready var cat = $cat_player   # Pfad anpassen

func _ready():
	print("[GAME] Test mit Katze und Ratten gestartet!")
	_InputManager.connect("rat_clicked", Callable(self, "_on_rat_clicked"))

func _on_rat_clicked(rat: Node3D):
	print("[GAME] Katze hat Ratte als Ziel:", rat.name)
	$cat_player.start_hunting(rat)
	if rat.has_method("start_fleeing"):
		rat.start_fleeing()
	else:
		print("[GAME][WARN] Ratte hat keine start_fleeing()-Methode!")
