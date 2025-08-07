extends Node
class_name InputManager

signal zoom_changed(new_zoom: float)
signal camera_rotated(delta_twist: float, delta_pitch: float)
signal escape_pressed()
signal rat_clicked(rat: Node3D)

@export var mouse_sensitivity := 0.002
var zoom_distance := 0.0
var input_unlocked := true

func _ready() -> void:
	print("[INPUT] Autoload InputManager ist aktiv.")
	set_process_unhandled_input(true)

	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	#print("[INPUT] input_unlocked =", input_unlocked)
	#print("[INPUT] Event empfangen:", event)
	if not input_unlocked:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_raycast_click()

	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_distance += 0.5
				emit_signal("zoom_changed", zoom_distance)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_distance -= 0.5
				emit_signal("zoom_changed", zoom_distance)

	elif event is InputEventMouseMotion:
		var delta_x = -event.relative.x * mouse_sensitivity
		var delta_y = -event.relative.y * mouse_sensitivity
		emit_signal("camera_rotated", delta_x, delta_y)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		input_unlocked = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("escape_pressed")
		
# ✅ Klick-RayCast
func _try_raycast_click():
	print("[INPUT] Starte Raycast-Test")
	var camera := get_viewport().get_camera_3d()
	if not camera:
		print("[INPUT][ERROR] Keine Kamera gefunden!")
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	print("[INPUT] Raycast gestartet → Mauspos:", mouse_pos)

	var space_state = camera.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	params.collision_mask = 0xFFFFFFFF  # <-- ALLE Layer testen!

	var result = space_state.intersect_ray(params)

	if result and result.has("collider"):
		var hit = result.collider
		print("[INPUT] Raycast Hit:", result)

		if hit.is_in_group("rats"):
			print("[INPUT] Treffer ist eine Ratte → Sende Signal!")
			emit_signal("rat_clicked", hit)
		else:
			print("[INPUT] Treffer:", hit.name, "→ KEINE Ratte.")
	else:
		print("[INPUT] Kein Treffer.")
