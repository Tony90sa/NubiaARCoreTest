extends Node3D

# Low-poly but fully 3D original 2026-style open-wheel race car.
func setup(team_color: Color, trim_color: Color, number: int, code: String) -> void:
	var paint := _mat(team_color, 0.47, 0.28)
	var trim := _mat(trim_color, 0.25, 0.3)
	var carbon := _mat(Color("#10141b"), 0.08, 0.7)
	var tire := _mat(Color("#101010"), 0.0, 0.96)
	var rim := _mat(Color("#aab1b7"), 0.8, 0.24)
	var glass := _mat(Color("#090c13"), 0.42, 0.2)
	_box(Vector3(1.1, 0.44, 3.55), Vector3(0, 0.6, 0), paint)
	_box(Vector3(0.63, 0.23, 2.4), Vector3(0, 0.45, -2.18), paint)
	_box(Vector3(1.6, 0.12, 0.38), Vector3(0, 0.51, -3.45), carbon)
	_box(Vector3(2.7, 0.11, 0.38), Vector3(0, 0.4, -3.86), paint)
	_box(Vector3(2.2, 0.08, 0.38), Vector3(0, 0.28, -4.13), carbon)
	_box(Vector3(2.35, 0.14, 0.50), Vector3(0, 1.27, 3.0), trim)
	_box(Vector3(2.46, 0.15, 0.38), Vector3(0, 1.08, 3.17), carbon)
	_box(Vector3(0.12, 0.90, 0.2), Vector3(-1.08, 0.88, 3.04), carbon)
	_box(Vector3(0.12, 0.90, 0.2), Vector3(1.08, 0.88, 3.04), carbon)
	_box(Vector3(0.55, 0.43, 1.2), Vector3(-0.82, 0.62, 0.38), paint)
	_box(Vector3(0.55, 0.43, 1.2), Vector3(0.82, 0.62, 0.38), paint)
	_box(Vector3(0.34, 0.13, 1.3), Vector3(-0.87, 0.93, 0.38), trim)
	_box(Vector3(0.34, 0.13, 1.3), Vector3(0.87, 0.93, 0.38), trim)
	_box(Vector3(0.65, 0.5, 1.38), Vector3(0, 0.93, 1.0), glass)
	_box(Vector3(0.82, 0.22, 0.11), Vector3(0, 1.41, 0.42), carbon)
	_box(Vector3(0.10, 0.22, 0.83), Vector3(-0.38, 1.34, 0.66), carbon)
	_box(Vector3(0.10, 0.22, 0.83), Vector3(0.38, 1.34, 0.66), carbon)
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.34
	helmet_mesh.height = 0.64
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0, 1.43, 0.55)
	helmet.material_override = trim
	add_child(helmet)
	_box(Vector3(0.55, 0.09, 0.25), Vector3(0, 1.49, 0.26), glass)
	for z in [-2.65, 2.35]:
		for side in [-1.0, 1.0]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.74
			wheel_mesh.bottom_radius = 0.74
			wheel_mesh.height = 0.51
			wheel_mesh.radial_segments = 18
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(side * 1.15, 0.66, z)
			wheel.rotation.z = PI * 0.5
			wheel.material_override = tire
			add_child(wheel)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.29
			hub_mesh.bottom_radius = 0.29
			hub_mesh.height = 0.535
			hub.mesh = hub_mesh
			hub.position = wheel.position
			hub.rotation.z = wheel.rotation.z
			hub.material_override = rim
			add_child(hub)
	var tag := Label3D.new()
	tag.text = "#%d  %s" % [number, code]
	tag.font_size = 64
	tag.pixel_size = 0.008
	tag.position = Vector3(0, 3.1, 0)
	tag.modulate = Color.WHITE
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	add_child(tag)

func _mat(tint: Color, metal: float, rough: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metal
	material.roughness = rough
	return material

func _box(size: Vector3, position3d: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = position3d
	part.material_override = material
	add_child(part)
