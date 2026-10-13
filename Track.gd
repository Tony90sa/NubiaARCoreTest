extends Node3D

# Aurora GP v0.2: long braking zones, chicane and two genuine low-speed hairpins.
# Original topology inspired by the *types* of corners found at Monza, Suzuka, Bahrain.
# Single non-overlapping road mesh (no stacked coplanar lines).
const HALF_WIDTH: float = 9.0
const ROAD_Y: float = 0.12
var curve: Curve3D
var length: float = 1.0
var _radius_cache: Dictionary = {}

func build() -> void:
	curve = Curve3D.new()
	curve.bake_interval = 2.0
	var points: Array[Vector3] = [
		Vector3(-405, 0, -335), Vector3(180, 0, -335),
		Vector3(390, 0, -320), Vector3(495, 0, -278),
		Vector3(540, 0, -216), Vector3(521, 0, -166),
		Vector3(451, 0, -149), Vector3(315, 0, -183),
		Vector3(181, 0, -115), Vector3(90, 0, 8),
		Vector3(146, 0, 153), Vector3(365, 0, 176),
		Vector3(455, 0, 286), Vector3(363, 0, 405),
		Vector3(198, 0, 381), Vector3(79, 0, 318),
		Vector3(-19, 0, 404), Vector3(-173, 0, 516),
		Vector3(-376, 0, 433), Vector3(-508, 0, 247),
		Vector3(-426, 0, 76), Vector3(-270, 0, 50),
		Vector3(-321, 0, -107), Vector3(-544, 0, -178),
		Vector3(-579, 0, -287), Vector3(-510, 0, -340)
	]
	for i in range(points.size()):
		var prev: Vector3 = points[(i - 1 + points.size()) % points.size()]
		var next: Vector3 = points[(i + 1) % points.size()]
		var handle: Vector3 = (next - prev) * 0.17
		curve.add_point(points[i], -handle, handle)
	var closing_handle: Vector3 = (points[1] - points[points.size() - 1]) * 0.17
	curve.add_point(points[0], -closing_handle, closing_handle)
	length = curve.get_baked_length()
	_add_ground()
	_add_asphalt_and_kerbs()
	_add_start_line()
	_add_scenery()
	_add_braking_boards()

func sample(distance: float) -> Vector3:
	return curve.sample_baked(fposmod(distance, length), true)

func forward(distance: float) -> Vector3:
	return (sample(distance + 2.0) - sample(distance - 2.0)).normalized()

func sideways(distance: float) -> Vector3:
	var dir: Vector3 = forward(distance)
	return Vector3(-dir.z, 0, dir.x)

func location(distance: float, lane: float) -> Vector3:
	return sample(distance) + sideways(distance) * lane

func direction_yaw(distance: float) -> float:
	var dir: Vector3 = forward(distance)
	return atan2(-dir.x, -dir.z)

func corner_radius(distance: float) -> float:
	var key: int = int(floor(fposmod(distance, length) / 5.0))
	if _radius_cache.has(key):
		return float(_radius_cache[key])
	var d: float = float(key) * 5.0
	var f0: Vector3 = forward(d - 7.0)
	var f1: Vector3 = forward(d + 7.0)
	var turn: float = acos(clampf(f0.dot(f1), -1.0, 1.0))
	var radius: float = 14.0 / maxf(turn, 0.005)
	_radius_cache[key] = radius
	return radius

func safe_corner_speed(distance: float) -> float:
	# Tuned to demand actual braking at the hairpins.
	return clampf(sqrt(29.0 * corner_radius(distance)), 17.0, 90.0)

func nearest_progress(world_pos: Vector3, reference: float) -> float:
	# Search only the next/previous 55 m: cannot jump between adjacent track segments.
	var best_d: float = reference
	var best_score: float = INF
	for i in range(-14, 15):
		var d: float = reference + float(i) * 4.0
		var pt: Vector3 = sample(d)
		var sqr: float = pt.distance_squared_to(world_pos)
		if sqr < best_score:
			best_score = sqr
			best_d = d
	for i in range(-10, 11):
		var refined: float = best_d + float(i) * 0.4
		var pt: Vector3 = sample(refined)
		var sqr: float = pt.distance_squared_to(world_pos)
		if sqr < best_score:
			best_score = sqr
			best_d = refined
	return best_d

func lane_of(world_pos: Vector3, progress: float) -> float:
	return (world_pos - sample(progress)).dot(sideways(progress))

func _mat(tint: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.vertex_color_use_as_albedo = true
	material.metallic = metallic
	material.roughness = 0.86
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _add_ground() -> void:
	var grass := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4000, 4000)
	grass.mesh = plane
	grass.position.y = -1.6
	grass.material_override = _mat(Color("#305d48"))
	add_child(grass)

func _add_asphalt_and_kerbs() -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: int = int(ceil(length / 3.0))
	# Distinct adjacent bands: shoulders, rumble strips, edge paint, asphalt.
	# Single mesh / one physical surface: no duplicate overlapping triangles.
	var edges: Array[float] = [-11.15, -9.0, -8.78, 8.78, 9.0, 11.15]
	for i in range(sections):
		var d0: float = float(i) * length / float(sections)
		var d1: float = float(i + 1) * length / float(sections)
		var p0: Vector3 = sample(d0) + Vector3.UP * ROAD_Y
		var p1: Vector3 = sample(d1) + Vector3.UP * ROAD_Y
		var s0: Vector3 = sideways(d0)
		var s1: Vector3 = sideways(d1)
		for band in range(edges.size() - 1):
			var c: Color = Color("#363b43")
			if band == 0 or band == 4:
				c = Color("#d7dbe1") if int(i / 3) % 2 == 0 else Color("#ce2942")
			elif band == 1 or band == 3:
				c = Color("#f3f3ec")
			elif int(i / 7) % 3 == 0:
				c = Color("#32373e")
			var a: Vector3 = p0 + s0 * edges[band]
			var b: Vector3 = p0 + s0 * edges[band + 1]
			var cc: Vector3 = p1 + s1 * edges[band]
			var dd: Vector3 = p1 + s1 * edges[band + 1]
			# Mark every triangle explicitly; no overlapping coplanar overlays.
			for vert in [a, b, cc, b, dd, cc]:
				mesh.set_color(c)
				mesh.add_vertex(vert)
	mesh.generate_normals()
	var road := MeshInstance3D.new()
	road.mesh = mesh.commit()
	road.material_override = _mat(Color.WHITE, 0.035)
	add_child(road)

func _add_start_line() -> void:
	var root := Node3D.new()
	root.position = location(0.0, 0.0)
	root.position.y = ROAD_Y + 0.055
	root.rotation.y = direction_yaw(0.0)
	add_child(root)
	for i in range(18):
		var box := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3(0.96, 0.035, 1.05)
		box.mesh = cube
		box.position = Vector3(-8.5 + float(i), 0, 0)
		box.material_override = _mat(Color("#e5e6e2") if i % 2 == 0 else Color("#161924"))
		root.add_child(box)

func _scenery_box(size: Vector3, loc: Vector3, yaw: float, color: Color) -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = loc
	box.rotation.y = yaw
	box.material_override = _mat(color, 0.12)
	add_child(box)

func _add_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 26
	var trunk_mat := _mat(Color("#4b4035"))
	var foliage := [_mat(Color("#265845")), _mat(Color("#39775a")), _mat(Color("#21513d"))]
	for i in range(int(length / 78.0)):
		var d: float = float(i) * 78.0
		for side in [-1.0, 1.0]:
			var p: Vector3 = location(d, side * rng.randf_range(55.0, 120.0))
			var trunk := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.38
			cylinder.bottom_radius = 0.65
			cylinder.height = 6
			trunk.mesh = cylinder
			trunk.position = p + Vector3.UP * 3
			trunk.material_override = trunk_mat
			add_child(trunk)
			var top := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = rng.randf_range(4.0, 6.0)
			sphere.height = sphere.radius * 2.0
			top.mesh = sphere
			top.position = p + Vector3.UP * 9.0
			top.material_override = foliage[rng.randi_range(0, 2)]
			add_child(top)
	# Pits/grandstand. Kept away from asphalt to avoid mesh intersections.
	for i in range(7):
		var d: float = 42.0 + float(i) * 46.0
		_scenery_box(Vector3(38, 8, 25), location(d, 53.0) + Vector3.UP * 4, direction_yaw(d), Color("#35455f"))
		_scenery_box(Vector3(39, 1, 27), location(d, 53.0) + Vector3.UP * 8.4, direction_yaw(d), Color("#d4dbe3"))
	for i in range(5):
		var d: float = 45.0 + float(i) * 58.0
		_scenery_box(Vector3(42, 6, 22), location(d, -56.0) + Vector3.UP * 3.0, direction_yaw(d), Color("#73869a"))

func _add_braking_boards() -> void:
	# Flat braking markers at entry to the first hairpin.
	for i in range(3):
		var distance: float = 410.0 - float(i) * 50.0
		var node := Label3D.new()
		node.text = "%dm" % [150 - i * 50]
		node.font_size = 100
		node.pixel_size = 0.007
		node.modulate = Color("#ffffff")
		node.outline_modulate = Color("#222d39")
		node.position = location(distance, -16.0) + Vector3.UP * 2.2
		node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(node)
