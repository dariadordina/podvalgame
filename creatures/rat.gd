extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
#@onready var anim_player: AnimationPlayer = $AnimationPlayer   # später aktivierbar

@export var wander_speed := 2.5 
@export var flee_speed := 7.0
var current_speed := wander_speed
@export var wander_radius := 5.0
@export var wander_interval := 3.0

var fleeing: bool = false
var wander_timer: float = 0.0
var start_position: Vector3
var escape_zones: Array = []

func _ready() -> void:
	print("[RAT] Ready! Initialisiere bei:", global_transform.origin)
	add_to_group("rats")
	start_position = global_transform.origin
	_find_escape_zones()

	# ✅ Debug: Prüfen, ob Agent eine Navigation hat
	if nav_agent.get_navigation_map() == RID():
		print("[RAT][WARN] NavigationAgent3D hat KEINE NavigationMap! → NavMesh fehlt oder nicht verbunden.")
	else:
		print("[RAT] NavigationAgent3D ist mit NavigationMap verbunden:", nav_agent.get_navigation_map())

	_set_random_wander_target()

func _physics_process(delta: float) -> void:
	if fleeing:
		print("[RAT] Fluchtmodus aktiv → Ziel:", nav_agent.target_position)
		_move_to_target(flee_speed, delta)
		if nav_agent.target_position.distance_to(global_transform.origin) < 1.0:
			print("[RAT] Fluchtziel erreicht → Ratte verschwindet!")
			queue_free()
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			_set_random_wander_target()
		_move_to_target(wander_speed, delta)

# -----------------------------
func _set_random_wander_target() -> void:
	var random_offset = Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	var wander_target = start_position + random_offset
	nav_agent.target_position = wander_target
	wander_timer = wander_interval
	print("[RAT] Neues Wanderziel:", wander_target)

# -----------------------------
func _move_to_target(move_speed: float, delta: float) -> void:
	if nav_agent.is_navigation_finished():
		#print("[RAT][DEBUG] Navigation beendet oder kein Pfad.")
		return

	var next_point = nav_agent.get_next_path_position()

	# ✅ Debug: Wenn Pfadpunkt gleich aktuelle Position → kein Pfad
	#if next_point.is_equal_approx(global_transform.origin):
		#print("[RAT][WARN] Kein gültiger Pfad! Agent steht fest.")
	#else:
		#print("[RAT][DEBUG] Nächster Pfadpunkt:", next_point)

	var dir = (next_point - global_transform.origin).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()

# -----------------------------
func start_fleeing() -> void:
	print("[RAT] Fluchtmodus aktiviert!")
	fleeing = true
	current_speed = flee_speed
	_find_escape_zones()
	
	if escape_zones.is_empty():
		print("[RAT][WARN] Keine EscapeZones gefunden!")
		return
	var closest = escape_zones[0]
	var min_dist = global_transform.origin.distance_to(closest.global_transform.origin)
	for zone in escape_zones:
		var d = global_transform.origin.distance_to(zone.global_transform.origin)
		if d < min_dist:
			closest = zone
			min_dist = d
	print("[RAT] Flucht gestartet → Zielzone:", closest.name, "| Distanz:", min_dist)
	nav_agent.target_position = closest.global_transform.origin
	fleeing = true

# -----------------------------
func _find_escape_zones() -> void:
	escape_zones.clear()
	for node in get_tree().get_nodes_in_group("escape_zones"):
		escape_zones.append(node)
	print("[RAT] Gefundene EscapeZones:", escape_zones.size())

# -----------------------------
func on_eaten() -> void:
	print("[RAT] Gefressen! → Entferne Ratte.")
	queue_free()
