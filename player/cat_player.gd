extends CharacterBody3D

# --- Nodes ---
@onready var twist_pivot: Node3D = $TwistPivot
@onready var pitch_pivot: Node3D = $TwistPivot/PitchPivot
@onready var camera_pivot: Camera3D = $TwistPivot/PitchPivot/Camera3D
@onready var raycast: RayCast3D = $TwistPivot/PitchPivot/RayCast3D
@onready var anim_player: AnimationPlayer = $Cat2/AnimationPlayer
@onready var model: Node3D = $Cat2
var hunting_target: Node3D = null
var hunting_speed := 8.0

# --- Animationen ---
const ANIM = {
	"idle": "cat_library/idle",
	"walk": "cat_library/walk",
	"run":  "cat_library/run",
	"jump": "cat_library/jump"
}

# --- Bewegung ---
@export var speed := 4.5
@export var run_speed := 8.0
@export var jump_velocity := 6.0
@export var gravity := -20.0

# --- Kamera-Rotation ---
var twist := 0.0
var pitch := 0.0
@export var pitch_min := deg_to_rad(-20)
@export var pitch_max := deg_to_rad(20)

# --- Kamera-Zoom ---
var zoom_distance := 0.0
@export var min_zoom := -1.0
@export var max_zoom := 1.0
var current_zoom := 0.0
var base_camera_position := Vector3.ZERO

# --------------------------------------------------
func _ready() -> void:
	add_to_group("player")
	init_camera_pivots(twist_pivot, pitch_pivot, camera_pivot)
	print("📷 base_camera_position:", base_camera_position)

	# ✅ Signale direkt vom Autoload "_InputManager" verbinden
	_InputManager.connect("zoom_changed", Callable(self, "update_zoom"))
	_InputManager.connect("camera_rotated", Callable(self, "_on_camera_rotated"))

# --------------------------------------------------
func _process(delta: float) -> void:
	_update_camera_collision()
	update_camera_controls(delta)

func _physics_process(delta: float) -> void:
	# 🐭 Wenn Jagd aktiv → handle Hunting separat
	if hunting_target:
		_handle_hunting(delta)
		return
	
	# 🐱 sonst normale Steuerung
	_handle_movement(delta)
	
	
# --------------------------------------------------
# --- MOVEMENT ---
func _handle_movement(delta: float) -> void:
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)

	var is_moving = input_dir.length() > 0.01
	var is_running = Input.is_action_pressed("move_run")

	var current_speed = speed
	if is_running:
		current_speed = run_speed

	# Kamera-Basis für Bewegung
	var basis = twist_pivot.global_transform.basis
	var cam_x = Vector3(basis.x.x, 0, basis.x.z).normalized()
	var cam_z = Vector3(basis.z.x, 0, basis.z.z).normalized()
	var direction = (cam_x * input_dir.x + cam_z * input_dir.y).normalized()

	# Bewegung
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Spieler drehen
	if is_moving:
		var target_rotation = atan2(direction.x, direction.z)
		var new_rotation = lerp_angle(model.rotation.y, target_rotation, 0.15)
		model.rotation.y = new_rotation
		$CollisionShape3D.rotation.y = new_rotation
		$CollisionShape3D2.rotation.y = new_rotation
		_play_movement_anim(is_running)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		_play_idle_anim()

	# Gravitation & Sprung
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			_play_jump_anim()

	move_and_slide()

# --------------------------------------------------
# --- CAMERA ---
func init_camera_pivots(twist_node: Node3D, pitch_node: Node3D, cam_node: Camera3D) -> void:
	twist_pivot = twist_node
	pitch_pivot = pitch_node
	camera_pivot = cam_node
	base_camera_position = camera_pivot.position

	# Float-Variablen initialisieren
	twist = twist_pivot.rotation.y
	pitch = pitch_pivot.rotation.x
	current_zoom = zoom_distance

func update_camera_controls(delta: float) -> void:
	twist_pivot.rotation.y = twist
	pitch_pivot.rotation.x = pitch
	current_zoom = lerp(current_zoom, zoom_distance, 5.0 * delta)
	camera_pivot.position = base_camera_position + Vector3(0, 0, -current_zoom)

func _update_camera_collision() -> void:
	var target_distance = 3.0
	var min_distance = 0.2
	if raycast.is_colliding():
		var dist = raycast.get_collision_point().distance_to(global_transform.origin)
		camera_pivot.position.z = -clamp(dist, min_distance, target_distance)
	else:
		camera_pivot.position.z = -target_distance

# --- Kamera-Input vom _InputManager ---
func update_zoom(amount: float) -> void:
	zoom_distance = clamp(amount, min_zoom, max_zoom)

func _on_camera_rotated(delta_twist: float, delta_pitch: float) -> void:
	twist += delta_twist
	pitch = clamp(pitch + delta_pitch, pitch_min, pitch_max)

# --------------------------------------------------
# --- ANIMATIONS ---
func _play_movement_anim(is_running: bool) -> void:
	if is_on_floor():
		if is_running:
			_play_anim_if_not_playing(ANIM["run"])
		else:
			_play_anim_if_not_playing(ANIM["walk"])

func _play_idle_anim() -> void:
	if is_on_floor():
		_play_anim_if_not_playing(ANIM["idle"])

func _play_jump_anim() -> void:
	_play_anim_if_not_playing(ANIM["jump"])

func _play_anim_if_not_playing(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
		
# --------------------------------------------------
# --- HUNTING ---
		
func start_hunting(rat: Node3D) -> void:
	if rat == null:
		print("[PLAYER] Kein Ziel angegeben.")
		return
	hunting_target = rat
	print("[PLAYER] Jagd gestartet → Ziel:", rat.name)
	
func _handle_hunting(delta: float) -> void:
	if not is_instance_valid(hunting_target):
		print("[PLAYER] Zielratte nicht mehr gültig → Jagd abgebrochen.")
		hunting_target = null
		return

	# 🟢 Gravitation berücksichtigen
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	var target_pos = hunting_target.global_transform.origin
	var distance = global_transform.origin.distance_to(target_pos)

	# Bewegung Richtung Ziel
	var direction = (target_pos - global_transform.origin).normalized()
	velocity.x = direction.x * hunting_speed
	velocity.z = direction.z * hunting_speed

	# Orientierung
	var target_rot = atan2(direction.x, direction.z)
	$Cat2.rotation.y = target_rot
	$CollisionShape3D.rotation.y = target_rot
	$CollisionShape3D2.rotation.y = target_rot

	# Wenn nah genug: fressen
	if distance < 1.0:
		print("[PLAYER] Hat Ratte erreicht! → Fressen...")
		if hunting_target.has_method("on_eaten"):
			hunting_target.on_eaten()
		hunting_target = null
		return
		
	if is_on_floor():
		_play_movement_anim(true)

	move_and_slide()
