extends StaticBody3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	# Lade dein OBJ als Mesh
	var mesh_res = load("res://assets/test_podval/podval_test_small.obj") 
	if mesh_res == null:
		push_error("Mesh konnte nicht geladen werden")
		return
	
	# MeshInstance erzeugen (für die visuelle Darstellung)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh_res
	add_child(mesh_instance)

	# CollisionShape aus dem Mesh erzeugen
	if mesh_res is ArrayMesh:
		var shape = mesh_res.create_trimesh_shape()
		collision_shape.shape = null      # wichtig, um alte Daten zu löschen
		collision_shape.shape = shape
	else:
		push_error("Mesh ist kein ArrayMesh und kann keine TrimeshShape erzeugen")
