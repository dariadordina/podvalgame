class_name Rat
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

@export var despawn_time := 12.0
@export var stuck_time := 2.0

var time_alive := 0.0
var time_stuck := 0.0

signal rat_despawned
signal rat_attack(cat)

var can_counterattack := false
var has_counterattacked := false

var player : Node3D

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

	player = get_tree().get_first_node_in_group("player")
	if player:
		print("[RAT] Spielerreferenz vorhanden:", player.name)
	else:
		print("[RAT][WARN] Keine Spielerreferenz! Signalverbindung möglicherweise fehlerhaft.")
	_set_random_wander_target()

func _physics_process(delta: float) -> void:
	time_alive += delta

	# 🟢 Falls zu lange lebt → prüfen, ob Spieler sie sieht
	if time_alive > despawn_time and not _player_looks_at_me():
		print("[RAT] Spieler schaut nicht → Ratte verschwindet.")
		queue_free()
		return

	# 🟢 Falls Navigation blockiert → Despawn
	if nav_agent and not nav_agent.is_navigation_finished():
		time_stuck = 0.0  # Normalfall
	else:
		time_stuck += delta
	if time_stuck > stuck_time:
		print("[RAT] Keine Navigation möglich → Ratte verschwindet.")
		queue_free()
		return

	if fleeing:
		#print("[RAT] Fluchtmodus aktiv → Ziel:", nav_agent.target_position)
		_move_to_target(flee_speed, delta)
		_try_counterattack()
		if nav_agent.target_position.distance_to(global_transform.origin) < 1.0:
			print("[RAT] Fluchtziel erreicht → Ratte verschwindet!")
			queue_free()
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			_set_random_wander_target()
		_move_to_target(wander_speed, delta)

func _player_looks_at_me() -> bool:
	var camera = player.get_node_or_null("TwistPivot/PitchPivot/Camera3D")
	if not camera:
		return false

	var to_rat = (global_transform.origin - camera.global_transform.origin).normalized()
	var forward = -camera.global_transform.basis.z.normalized()
	var dot = forward.dot(to_rat)

	# 🟢 Wenn Ratte grob innerhalb 60° Sichtfeld ist → sichtbar
	return dot > 0.5

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
		return

	var next_point = nav_agent.get_next_path_position()
	var dir = (next_point - global_transform.origin).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()

# -----------------------------
func start_fleeing() -> void:
	print("[RAT] Fluchtmodus aktiviert!")
	fleeing = true
	current_speed = flee_speed
	can_counterattack = randf() < 0.75
	print("[RAT] Kann kontern:", can_counterattack)
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

func _despawn():
	print("[RAT] Despawn → sende Signal an Spawner")
	emit_signal("rat_despawned", self)
	queue_free()

func _try_counterattack():
	if not can_counterattack:
		print("[RAT] ❌ Kein Gegenangriff erlaubt.")
		return

	if has_counterattacked:
		print("[RAT] ⚠️ Bereits angegriffen.")
		return

	if not is_instance_valid(player):
		print("[RAT] ❌ Spieler-Referenz ungültig.")
		return

	var dist = global_transform.origin.distance_to(player.global_transform.origin)
	print("[RAT] Prüfe Angriff… Distanz zur Katze:", dist)

	if dist < 10.0:
		print("[RAT] ✅ Führt Gegenangriff aus!")
		emit_signal("rat_attack", player)
		has_counterattacked = true
	else:
		print("[RAT] ❌ Zu weit entfernt zum Angreifen.")
