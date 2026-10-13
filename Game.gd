extends Node3D

# GRID 26 — unofficial arcade prototype. Fictional track, original 3D models.
const LAPS := 3
const TEAMS := [
	["Mercedes", "#37d8cc", "#111923", 1.000, 578],
	["Ferrari", "#ec263c", "#ffe04d", 0.983, 444],
	["McLaren", "#ff9135", "#181b2b", 0.970, 339],
	["Red Bull Racing", "#142c77", "#f4c935", 0.976, 332],
	["Racing Bulls", "#ecf3ff", "#315aca", 0.941, 100],
	["Alpine", "#e878af", "#378ed0", 0.932, 68],
	["Haas", "#eeeef0", "#e32c30", 0.917, 30],
	["Audi", "#bbc1c6", "#e52832", 0.911, 23],
	["Williams", "#1973e5", "#f4f7ff", 0.905, 12],
	["Aston Martin", "#116c55", "#e4ff9e", 0.898, 7],
	["Cadillac", "#3c4149", "#fafafa", 0.884, 0]
]
const ROSTER := [
	["George Russell", 0, 63, 1.015, "RUS"],
	["Kimi Antonelli", 0, 12, 1.040, "ANT"],
	["Charles Leclerc", 1, 16, 1.030, "LEC"],
	["Lewis Hamilton", 1, 44, 1.025, "HAM"],
	["Lando Norris", 2, 1, 1.025, "NOR"],
	["Oscar Piastri", 2, 81, 1.010, "PIA"],
	["Max Verstappen", 3, 3, 1.045, "VER"],
	["Isack Hadjar", 3, 6, 0.999, "HAD"],
	["Liam Lawson", 4, 30, 1.015, "LAW"],
	["Arvid Lindblad", 4, 41, 0.990, "LIN"],
	["Pierre Gasly", 5, 10, 1.014, "GAS"],
	["Franco Colapinto", 5, 43, 0.990, "COL"],
	["Esteban Ocon", 6, 31, 0.993, "OCO"],
	["Oliver Bearman", 6, 87, 1.008, "BEA"],
	["Nico Hulkenberg", 7, 27, 1.010, "HUL"],
	["Gabriel Bortoleto", 7, 5, 0.998, "BOR"],
	["Carlos Sainz", 8, 55, 1.006, "SAI"],
	["Alexander Albon", 8, 23, 1.003, "ALB"],
	["Fernando Alonso", 9, 14, 1.022, "ALO"],
	["Lance Stroll", 9, 18, 0.970, "STR"],
	["Sergio Perez", 10, 11, 0.995, "PER"],
	["Valtteri Bottas", 10, 77, 1.002, "BOT"]
]
var circuit: Node3D
var cars: Array[Dictionary] = []
var player: Dictionary = {}
var camera: Camera3D
var chosen_index := 0
var grid_position := 12
var turning := 0.0
var braking := false
var boosting := false
var racing := false
var finished := false
var race_time := 0.0
var boost_meter := 100.0
var menu_layer: CanvasLayer
var menu_root: Control
var hud_layer: CanvasLayer
var hud_root: Control
var driver_choice: OptionButton
var grid_choice: OptionButton
var lap_label: Label
var pos_label: Label
var speed_label: Label
var boost_label: Label
var chasing_label: Label

func _ready() -> void:
	_make_menu()

func _create_label(message: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)
	var bg := ColorRect.new()
	bg.color = Color("#0b1223")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(bg)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -400.0
	panel.offset_right = 400.0
	panel.offset_top = -305.0
	panel.offset_bottom = 305.0
	menu_root.add_child(panel)
	var padding := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(padding)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	padding.add_child(col)
	col.add_child(_create_label("GRID 26  |  GRAND PRIX", 43, Color("#f6c852")))
	col.add_child(_create_label("STAGIONE 2026  •  11 SCUDERIE  •  22 PILOTI", 20, Color("#c4d2e4")))
	col.add_child(_create_label("Scegli pilota e posizione sulla griglia", 21, Color.WHITE))
	driver_choice = OptionButton.new()
	driver_choice.custom_minimum_size.y = 52.0
	for driver in ROSTER:
		driver_choice.add_item("%s  |  %s  #%d" % [driver[0], TEAMS[int(driver[1])][0], driver[2]])
	col.add_child(driver_choice)
	col.add_child(_create_label("Posizione di partenza", 20, Color("#c4d2e4")))
	grid_choice = OptionButton.new()
	grid_choice.custom_minimum_size.y = 52.0
	for i in range(1, 23):
		grid_choice.add_item("P%d / 22" % i)
	grid_choice.select(11)
	col.add_child(grid_choice)
	col.add_child(_create_label("CIRCUITO AURORA   ·   3 GIRI   ·   SOLO GARA", 18, Color("#70e2d3")))
	var race_button := Button.new()
	race_button.text = "PARTI  →"
	race_button.custom_minimum_size.y = 66.0
	race_button.add_theme_font_size_override("font_size", 27)
	race_button.pressed.connect(_start_race)
	col.add_child(race_button)
	col.add_child(_create_label("Accelerazione automatica · sterza · frena · usa il BOOST", 17, Color("#abb7ca")))

func _start_race() -> void:
	if racing:
		return
	chosen_index = driver_choice.selected
	grid_position = grid_choice.selected + 1
	menu_root.hide()
	_setup_environment()
	circuit = preload("res://Track.gd").new()
	add_child(circuit)
	circuit.build()
	_make_grid()
	_make_camera()
	_make_hud()
	race_time = 0.0
	boost_meter = 100.0
	finished = false
	racing = true

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#91bfd6")
	sky.ambient_light_color = Color("#c7dded")
	sky.ambient_light_energy = 0.75
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = sky
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -35.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

func _driver_pace(idx: int) -> float:
	var driver: Array = ROSTER[idx]
	return float(TEAMS[int(driver[1])][3]) * float(driver[3])

func _make_grid() -> void:
	var starting_order: Array[int] = []
	for i in range(ROSTER.size()):
		if i != chosen_index:
			starting_order.append(i)
	starting_order.sort_custom(func(a: int, b: int) -> bool: return _driver_pace(a) > _driver_pace(b))
	starting_order.insert(grid_position - 1, chosen_index)
	for slot in range(starting_order.size()):
		var idx: int = starting_order[slot]
		var driver: Array = ROSTER[idx]
		var team: Array = TEAMS[int(driver[1])]
		var node: Node3D = preload("res://Car.gd").new()
		node.setup(Color(team[1]), Color(team[2]), int(driver[2]), String(driver[4]))
		add_child(node)
		var lane := -3.0 if slot % 2 == 0 else 3.0
		var entry: Dictionary = {
			"index": idx, "node": node, "progress": -float(int(slot / 2)) * 14.0,
			"lane": lane, "target_lane": lane, "speed": 0.0, "finished": false
		}
		cars.append(entry)
		if idx == chosen_index:
			player = entry
		_position_car(entry)

func _position_car(entry: Dictionary) -> void:
	var progress := float(entry["progress"])
	var node: Node3D = entry["node"]
	node.position = circuit.location(progress, float(entry["lane"]))
	node.position.y += 0.04
	node.rotation.y = circuit.direction_yaw(progress)

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 70.0
	camera.far = 2300.0
	add_child(camera)
	camera.global_position = (player["node"] as Node3D).global_position + Vector3(0, 8, 20)
	_camera_follow(0.5)

func _camera_follow(delta: float) -> void:
	var node: Node3D = player["node"]
	var rot := Basis(Vector3.UP, node.rotation.y)
	var behind: Vector3 = rot * Vector3(0, 7.0, 18.0)
	var ahead: Vector3 = rot * Vector3(0, 1.3, -13.0)
	camera.global_position = camera.global_position.lerp(node.global_position + behind, clampf(delta * 4.2, 0.0, 1.0))
	camera.look_at(node.global_position + ahead, Vector3.UP)

func _make_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)
	lap_label = _create_label("GIRO 1/3", 26, Color.WHITE)
	lap_label.position = Vector2(24, 14)
	hud_root.add_child(lap_label)
	pos_label = _create_label("P12/22", 35, Color("#ffd55b"))
	pos_label.position = Vector2(24, 50)
	hud_root.add_child(pos_label)
	speed_label = _create_label("0 KM/H", 26, Color.WHITE)
	speed_label.anchor_left = 1.0
	speed_label.anchor_right = 1.0
	speed_label.offset_left = -255
	speed_label.offset_right = -16
	speed_label.offset_top = 19
	hud_root.add_child(speed_label)
	boost_label = _create_label("BOOST 100%", 24, Color("#60eadb"))
	boost_label.anchor_left = 1.0
	boost_label.anchor_right = 1.0
	boost_label.offset_left = -255
	boost_label.offset_right = -15
	boost_label.offset_top = 59
	hud_root.add_child(boost_label)
	chasing_label = _create_label("", 18, Color.WHITE)
	chasing_label.position = Vector2(24, 98)
	hud_root.add_child(chasing_label)
	var left := _make_button("◀", -1.0, 18, 154, 28, -153)
	left.button_down.connect(_turn_left_down)
	left.button_up.connect(_turn_left_up)
	var right := _make_button("▶", -1.0, 164, 300, 28, -153)
	right.button_down.connect(_turn_right_down)
	right.button_up.connect(_turn_right_up)
	var brake := _make_button("FRENO", 1.0, -340, -190, -170, -20)
	brake.button_down.connect(_brake_down)
	brake.button_up.connect(_brake_up)
	var boost := _make_button("BOOST", 1.0, -180, -18, -170, -20)
	boost.button_down.connect(_boost_down)
	boost.button_up.connect(_boost_up)
	# Change steering control offsets to anchor at the bottom.
	for button in [left, right]:
		button.anchor_top = 1.0
		button.anchor_bottom = 1.0
		button.offset_top = -170
		button.offset_bottom = -20

func _make_button(caption: String, horizontal_anchor: float, left: float, right: float, top: float, bottom: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 25)
	button.anchor_left = horizontal_anchor
	button.anchor_right = horizontal_anchor
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left
	button.offset_right = right
	button.offset_top = top
	button.offset_bottom = bottom
	hud_root.add_child(button)
	return button

func _turn_left_down() -> void:
	turning = -1.0
func _turn_left_up() -> void:
	if turning < 0: turning = 0.0
func _turn_right_down() -> void:
	turning = 1.0
func _turn_right_up() -> void:
	if turning > 0: turning = 0.0
func _brake_down() -> void:
	braking = true
func _brake_up() -> void:
	braking = false
func _boost_down() -> void:
	boosting = true
func _boost_up() -> void:
	boosting = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event
	if key.keycode == KEY_LEFT or key.keycode == KEY_A:
		turning = -1.0 if key.pressed else 0.0
	elif key.keycode == KEY_RIGHT or key.keycode == KEY_D:
		turning = 1.0 if key.pressed else 0.0
	elif key.keycode == KEY_DOWN or key.keycode == KEY_S:
		braking = key.pressed
	elif key.keycode == KEY_SPACE:
		boosting = key.pressed

func _process(delta: float) -> void:
	if not racing or finished:
		return
	delta = minf(delta, 0.05)
	race_time += delta
	for entry in cars:
		if entry == player:
			continue
		_update_ai(entry, delta)
	_update_player(delta)
	for entry in cars:
		_position_car(entry)
	_camera_follow(delta)
	_update_hud()
	if float(player["progress"]) >= circuit.length * float(LAPS):
		_finish()

func _update_ai(entry: Dictionary, delta: float) -> void:
	var idx := int(entry["index"])
	var progress := float(entry["progress"])
	var base_speed := 75.0 * _driver_pace(idx)
	var desired := base_speed * (1.0 - circuit.curve_factor(progress))
	var lane := float(entry["lane"])
	var target_lane := float(entry["target_lane"])
	var closest := 1000.0
	for other in cars:
		if other == entry:
			continue
		var gap := float(other["progress"]) - progress
		if gap > 0.0 and gap < closest and gap < 45.0 and absf(float(other["lane"]) - lane) < 2.7:
			closest = gap
			if gap < 32.0:
				var preference := 1.0 if idx % 2 == 0 else -1.0
				var candidate := float(other["lane"]) + preference * 3.5
				if absf(candidate) > 6.4:
					candidate = float(other["lane"]) - preference * 3.5
				var free := true
				for blocker in cars:
					if blocker == entry:
						continue
					if absf(float(blocker["progress"]) - progress) < 13.0 and absf(float(blocker["lane"]) - candidate) < 2.2:
						free = false
						break
				if free:
					target_lane = candidate
				else:
					desired = minf(desired, float(other["speed"]) + maxf((gap - 7.0) * 0.5, 0.0))
	if closest > 54.0 and absf(target_lane) > 0.4:
		target_lane = 0.0
	if closest > 35.0:
		target_lane = move_toward(target_lane, 0.0, delta * 0.8)
	entry["target_lane"] = clampf(target_lane, -6.1, 6.1)
	entry["lane"] = move_toward(lane, float(entry["target_lane"]), delta * 4.1)
	entry["speed"] = move_toward(float(entry["speed"]), desired, delta * 18.0)
	entry["progress"] = progress + float(entry["speed"]) * delta

func _update_player(delta: float) -> void:
	var progress := float(player["progress"])
	var base_speed := 75.0 * _driver_pace(chosen_index)
	var target := base_speed * (1.0 - circuit.curve_factor(progress))
	var active_boost := boosting and boost_meter > 1.0 and not braking
	if active_boost:
		target += 11.0
		boost_meter = maxf(0.0, boost_meter - delta * 25.0)
	else:
		boost_meter = minf(100.0, boost_meter + delta * 7.0)
	if braking:
		target *= 0.42
	var lane := clampf(float(player["lane"]) + turning * delta * 8.2, -6.1, 6.1)
	# Collision avoidance: stay behind cars until choosing a clear side.
	for other in cars:
		if other == player:
			continue
		var gap := float(other["progress"]) - progress
		if gap > 0.0 and gap < 17.0 and absf(float(other["lane"]) - lane) < 2.45:
			target = minf(target, float(other["speed"]) + maxf(0.0, (gap - 5.0) * 0.6))
	player["lane"] = lane
	player["speed"] = move_toward(float(player["speed"]), target, delta * (35.0 if braking else 15.0))
	player["progress"] = progress + float(player["speed"]) * delta

func _sorted_field() -> Array[Dictionary]:
	var order: Array[Dictionary] = cars.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["progress"]) > float(b["progress"]))
	return order

func _update_hud() -> void:
	var progress := float(player["progress"])
	var lap := clampi(int(floor(progress / circuit.length)) + 1, 1, LAPS)
	lap_label.text = "GIRO %d/%d  ·  AURORA" % [lap, LAPS]
	var rank := _sorted_field().find(player) + 1
	pos_label.text = "P%d / 22" % rank
	speed_label.text = "%d KM/H" % int(float(player["speed"]) * 3.6)
	boost_label.text = "BOOST  %d%%" % int(boost_meter)
	var rival_name := "PISTA LIBERA"
	var nearest := 10000.0
	for entry in cars:
		if entry == player:
			continue
		var gap := float(entry["progress"]) - progress
		if gap > 0.0 and gap < nearest:
			nearest = gap
			rival_name = "%s  +%.0fm" % [ROSTER[int(entry["index"])][0], gap]
	chasing_label.text = rival_name

func _finish() -> void:
	finished = true
	var rank := _sorted_field().find(player) + 1
	var layer := CanvasLayer.new()
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0.035, 0.055, 0.09, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var col := VBoxContainer.new()
	col.anchor_left = 0.28
	col.anchor_right = 0.72
	col.anchor_top = 0.22
	col.anchor_bottom = 0.78
	col.add_theme_constant_override("separation", 23)
	overlay.add_child(col)
	col.add_child(_create_label("BANDIERA A SCACCHI!", 40, Color("#f5d159")))
	col.add_child(_create_label("POSIZIONE FINALE: P%d / 22" % rank, 29, Color.WHITE))
	col.add_child(_create_label("TEMPO: %02d:%05.2f" % [int(race_time / 60.0), fmod(race_time, 60.0)], 24, Color("#70e2d3")))
	var btn := Button.new()
	btn.text = "GARA TERMINATA"
	btn.custom_minimum_size.y = 70.0
	col.add_child(btn)
