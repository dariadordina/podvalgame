extends Node3D
class_name RatSpawner

@export var rat_scene: PackedScene
@export var max_rats: int = 5
@export var spawn_interval: float = 6.0
@export var spawn_radius: float = 15.0   # max. Distanz zum Player
@export var min_distance: float = 4.0    # nicht direkt vor der Katze

var _spawn_timer: float = 0.0
var player: Node3D
var camera: Camera3D

func _ready():
	# Player + Kamera finden
	player = get_tree().get_nodes_in_group("player").front() if get_tree().has_group("player") else null
	camera = get_viewport().get_camera_3d()
	if not player:
		print("[SPAWNER][WARN] Kein Player gefunden!")
	else:
		print("[SPAWNER] Player erkannt:", player.name)

func _process(delta: float):
	if not player or not camera:
		return

	if get_tree().get_nodes_in_group("rats").size() >= max_rats:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_timer = spawn_interval
		_try_spawn_near_player()

func _try_spawn_near_player():
	var origin = player.global_transform.origin

	# 3 Versuche, um einen guten Punkt zu finden
	for i in range(3):
		var random_dir = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized()
		var distance = randf_range(min_distance, spawn_radius)
		var spawn_pos = origin + random_dir * distance
		spawn_pos.y = 0.1

		# 🔍 Sichtprüfung
		if _is_point_hidden_from_camera(spawn_pos):
			_spawn_rat(spawn_pos)
			return

	print("[SPAWNER] Kein verdeckter Spawnpunkt gefunden → kein Spawn diesmal.")

func _is_point_hidden_from_camera(point: Vector3) -> bool:
	# 1️⃣ Prüfen, ob Punkt VOR der Kamera liegt
	if camera.is_position_behind(point):
		return true  # hinter Kamera → kein Spawn hier

	# 2️⃣ Prüfen, ob Punkt im Viewport ist
	var screen_pos = camera.unproject_position(point)  # → Vector2
	if screen_pos.x >= 0 and screen_pos.x <= camera.get_viewport().size.x \
	and screen_pos.y >= 0 and screen_pos.y <= camera.get_viewport().size.y:
		# Punkt im Sichtfeld → muss zusätzlich durch Raycast verdeckt sein
		return not _is_visible_from_camera(point)

	return true  # Punkt außerhalb des Bildschirms → Spawn erlaubt

func _is_visible_from_camera(point: Vector3) -> bool:
	# 2️⃣ Raycast: sieht die Kamera direkt den Punkt?
	var from = camera.global_transform.origin
	var to = point
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	var hit = space.intersect_ray(ray)

	if not hit:
		return true  # kein Hindernis → Punkt direkt sichtbar
	return false    # Hindernis dazwischen → Punkt ist versteckt

func _spawn_rat(spawn_position: Vector3 = Vector3.ZERO):
	# Falls keine Position angegeben → generiere eine zufällige um den Player
	if spawn_position == Vector3.ZERO:
		var origin = player.global_transform.origin
		var random_dir = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized()
		var distance = randf_range(min_distance, spawn_radius)
		spawn_position = origin + random_dir * distance
		spawn_position.y = 0.1

	var rat = rat_scene.instantiate()
	rat.global_transform.origin = spawn_position
	add_child(rat)

	# Signal verbinden → sofort neuen Spawn bei Despawn
	rat.connect("rat_despawned", Callable(self, "_on_rat_despawned"))
	print("[SPAWNER] Neue Ratte gespawnt bei:", spawn_position)
	
func _on_rat_despawned(rat):
	print("[SPAWNER] Ratte verschwunden → spawne neue.")
	_spawn_rat()
