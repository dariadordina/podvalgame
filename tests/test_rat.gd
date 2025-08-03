extends Node3D

func _ready():
	print("[GAME] Test-Szene gestartet. Warte auf Klicks...")
	_InputManager.connect("rat_clicked", Callable(self, "_on_rat_clicked"))

func _on_rat_clicked(rat: Node3D):
	print("[GAME] Ratte angeklickt:", rat.name)
	rat.start_fleeing()
