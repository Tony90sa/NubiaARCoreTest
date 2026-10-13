extends Node3D

# Fictional high-speed circuit: closed cubic Bezier spline and procedural scenery.
const HALF_WIDTH := 9.0
var curve: Curve3D
var length: float = 1.0

func build() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 3.0
	var points: Array[Vector3] = [
		Vector3(-240, 0, -320), Vector3(140, 0, -320),
		Vector3(430, 0, -260), Vector3(560, 0, -70),
		Vector3(480, 0, 180), Vector3(190, 0, 320),
		Vector3(50, 0, 540), Vector3(-250, 0, 550),
		Vector3(-470, 0, 420), Vector3(-600, 0, 210),
		Vector3(-550, 0, -100), Vector3(-390, 0, -180)
	]
	var count := points.size()
	for i in range(count):
		var tangent: Vector3 = (points[(i + 1) % count] - points[(i - 1 + count) % count]) * 0.20
		curve.add_point(points[i], -tangent, tangent)
	var closure: Vector3 = (points[1] - points[count - 1]) * 0.20
	curve.add_point(points[0], -closure, closure)
	length = curve.get_baked_length()
	_ground()
	_strip(-HALF_WIDTH, HALF_WIDTH, 0.02, Color("#282d36"), false, false)
	_strip(-HALF_WIDTH - 2.0, -HALF_WIDTH, 0.015, Color("#f4f4f4"), true, false)
	_strip(HALF_WIDTH, HALF_WIDTH + 2.0, 0.015, Color("#f4f4f4"), true, false)
	_strip(-HALF_WIDTH + 0.6, -HALF_WIDTH + 0.82, 0.04, Color("#fafafa"), false, false)
	_strip(HALF_WIDTH - 0.82, HALF_WIDTH - 0.6, 0.04, Color("#fafafa"), false, false)
	_strip(-0.09, 0.09, 0.047, Color("#ffd84f"), false, true)
	_start_line()
	_decor()

func sample(d: float) -> Vector3:
	return curve.sample_baked(fposmod(d, length), true)

func forward(d: float) -> Vector3:
	return (sample(d + 3.0) - sample(d - 3.0)).normalized()

func sideways(d: float) -> Vector3:
	var f := forward(d)
	return Vector3(-f.z, 0, f.x)

func location(d: float, lane: float) -> Vector3:
	return sample(d) + sideways(d) * lane

func direction_yaw(d: float) -> float:
	var f := forward(d)
	return atan2(-f.x, -f.z)

func curve_factor(d: float) -> float:
	var f1 := forward(d - 22.0)
	var f2 := forward(d + 22.0)
	return clampf((1.0 - f1.dot(f2)) * 2.4, 0.0, 0.32)

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _ground() -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(3000, 3000)
	plane.mesh = mesh
	plane.position.y = -0.15
	plane.material_override = _material(Color("#29634b"))
	add_child(plane)

func _strip(left: float, right: float, height: float, base: Color, alternates: bool, dashed: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections := int(ceil(length / 4.0))
	for i in range(sections):
		if dashed and i % 12 > 6:
			continue
		var d0 := float(i) * length / float(sections)
		var d1 := float(i + 1) * length / float(sections)
		var p0 := sample(d0) + Vector3.UP * height
		var p1 := sample(d1) + Vector3.UP * height
		var s0 := sideways(d0)
		var s1 := sideways(d1)
		var shade: Color = base
		if alternates and int(i / 3) % 2 == 0:
			shade = Color("#e23a4b")
		var a := p0 + s0 * left
		var b := p0 + s0 * right
		var c := p1 + s1 * left
		var d := p1 + s1 * right
		for v in [a, b, c, b, d, c]:
			st.set_color(shade)
			st.add_vertex(v)
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	var mat := _material(Color.WHITE, 0.05)
	mat.vertex_color_use_as_albedo = true
	node.material_override = mat
	add_child(node)

func _start_line() -> void:
	var p := sample(0.0)
	var yaw := direction_yaw(0.0)
	for x in range(-9, 9, 2):
		for z in range(2):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(2.0, 0.03, 1.5)
			tile.mesh = mesh
			tile.position = p + sideways(0.0) * (float(x) + 1.0) + forward(0.0) * (float(z) - 0.5)
			tile.position.y = 0.065
			tile.rotation.y = yaw
			tile.material_override = _material(Color.WHITE if (int(x / 2) + z) % 2 == 0 else Color("#11121a"))
			add_child(tile)

func _decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 262626
	var trunk_mat := _material(Color("#44382a"))
	var leaf_mats := [_material(Color("#1c4b36")), _material(Color("#337759")), _material(Color("#245e42"))]
	for i in range(int(length / 58.0)):
		var distance := float(i) * 58.0
		for side in [-1.0, 1.0]:
			var world_pos := location(distance, side * rng.randf_range(42.0, 88.0))
			var trunk := MeshInstance3D.new()
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.38
			trunk_mesh.bottom_radius = 0.6
			trunk_mesh.height = 6.0
			trunk.mesh = trunk_mesh
			trunk.position = world_pos + Vector3.UP * 3.0
			trunk.material_override = trunk_mat
			add_child(trunk)
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = rng.randf_range(4.0, 6.5)
			crown_mesh.height = crown_mesh.radius * 2.0
			crown.mesh = crown_mesh
			crown.position = world_pos + Vector3.UP * 9.0
			crown.material_override = leaf_mats[rng.randi_range(0, 2)]
			add_child(crown)
	# Pit building and spectator grandstands alongside the main straight.
	for i in range(6):
		var d := 32.0 + i * 37.0
		var pos := location(d, -42.0)
		var grandstand := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(29.0, 9.0, 22.0)
		grandstand.mesh = mesh
		grandstand.position = pos + Vector3.UP * 4.5
		grandstand.rotation.y = direction_yaw(d)
		grandstand.material_override = _material(Color("#8798a9") if i % 2 == 0 else Color("#424f66"), 0.18)
		add_child(grandstand)
	for i in range(4):
		var d := 52.0 + i * 55.0
		var pit := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(42.0, 8.0, 27.0)
		pit.mesh = box
		pit.position = location(d, 39.0) + Vector3.UP * 4.0
		pit.rotation.y = direction_yaw(d)
		pit.material_override = _material(Color("#26364e"), 0.3)
		add_child(pit)
		var roof := MeshInstance3D.new()
		var roof_box := BoxMesh.new()
		roof_box.size = Vector3(44.0, 1.2, 29.0)
		roof.mesh = roof_box
		roof.position = pit.position + Vector3.UP * 4.7
		roof.rotation.y = pit.rotation.y
		roof.material_override = _material(Color("#dce2e7"), 0.5)
		add_child(roof)
