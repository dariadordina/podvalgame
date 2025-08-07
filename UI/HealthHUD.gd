extends CanvasLayer

@onready var bar = $MarginContainer/HealthBar
var _last_value: float

func _ready():
	_last_value = bar.value
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Initiale Werte setzen
		bar.min_value = 0
		bar.max_value = player.max_health
		bar.value = player.health
		# Auf Health-Änderungen hören
		player.connect("health_changed", Callable(self, "_on_health_changed"))
	else:
		push_warning("HUD: Kein Player gefunden – HealthBar bleibt statisch.")

func _on_health_changed(current: int, maxv: int):
	if current < _last_value:
		flash_damage()
	_last_value = current
	bar.max_value = maxv
	bar.value = current
	
	var _last_value := 0

func flash_damage():
	# kurzer Tint-Flash (falls du TextureProgressBar hast)
	var tween = create_tween()
	bar.modulate = Color(1,0.3,0.3)
	tween.tween_property(bar, "modulate", Color(1,1,1), 0.2)
