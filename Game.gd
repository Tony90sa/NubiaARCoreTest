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
var circuit
var cars: Array[Dictionary] = []
var player: Dictionary = {}
var camera: Camera3D
var chosen_index := 0
var grid_position := 12
var turning := 0.0
var accelerating := false
var braking := false
var player_world_pos := Vector3.ZERO
var player_heading := 0.0
var offroad_seconds := 0.0
var reset_count := 0
var start_delay := 0.0
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
var notice_label: Label

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
	col.add_child(_create_label("AURORA GP v0.2 · 3 GIRI · STACCATE E CHICANE", 18, Color("#70e2d3")))
	var race_button := Button.new()
	race_button.text = "PARTI  →"
	race_button.custom_minimum_size.y = 66.0
	race_button.add_theme_font_size_override("font_size", 27)
	race_button.pressed.connect(_start_race)
	col.add_child(race_button)
	col.add_child(_create_label("Guida manuale: ACCELERA · FRENO · STERZA · BOOST", 17, Color("#abb7ca")))

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
	start_delay = 3.0
	boost_meter = 100.0
	offroad_seconds = 0.0
	reset_count = 0
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
	sun.shadow_enabled = false # Avoid mobile cascade shadow striping / acne
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
		node.call("setup", Color(team[1]), Color(team[2]), int(driver[2]), String(driver[4]))
		add_child(node)
		var lane := -3.0 if slot % 2 == 0 else 3.0
		var entry: Dictionary = {
			"index": idx, "node": node, "progress": -float(int(slot / 2)) * 17.0,
			"lane": lane, "target_lane": lane, "speed": 0.0, "finished": false
		}
		cars.append(entry)
		if idx == chosen_index:
			player = entry
		_position_car(entry)
	player_world_pos = circuit.location(float(player["progress"]), float(player["lane"]))
	player_world_pos.y = float(circuit.ROAD_Y) + 0.04
	player_heading = circuit.direction_yaw(float(player["progress"]))

func _position_car(entry: Dictionary) -> void:
	var progress := float(entry["progress"])
	var node: Node3D = entry["node"]
	node.position = circuit.location(progress, float(entry["lane"]))
	node.position.y += float(circuit.ROAD_Y) + 0.04
	node.rotation.y = circuit.direction_yaw(progress)

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 78.0
	# Lower far/near ratio greatly reduces depth precision artifacts on Adreno GPUs.
	camera.near = 0.23
	camera.far = 900.0
	add_child(camera)
	_camera_follow(1.0)

func _camera_follow(delta: float) -> void:
	var rotation_basis := Basis(Vector3.UP, player_heading)
	# Only ~1.3 m behind the tip of the rear wing.
	var target: Vector3 = player_world_pos + rotation_basis * Vector3(0.0, 2.38, 4.45)
	var focus: Vector3 = player_world_pos + rotation_basis * Vector3(0.0, 1.05, -17.0)
	camera.global_position = camera.global_position.lerp(target, clampf(delta * 13.0, 0.0, 1.0))
	camera.look_at(focus, Vector3.UP)

func _make_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)
	lap_label = _create_label("GIRO 1/3", 26, Color.WHITE)
	lap_label.position = Vector2(24, 12)
	hud_root.add_child(lap_label)
	pos_label = _create_label("P12/22", 35, Color("#ffe069"))
	pos_label.position = Vector2(24, 49)
	hud_root.add_child(pos_label)
	speed_label = _create_label("0 KM/H", 26, Color.WHITE)
	speed_label.anchor_left = 1.0
	speed_label.anchor_right = 1.0
	speed_label.offset_left = -260
	speed_label.offset_right = -14
	speed_label.offset_top = 15
	hud_root.add_child(speed_label)
	boost_label = _create_label("BOOST 100%", 24, Color("#60eadb"))
	boost_label.anchor_left = 1.0
	boost_label.anchor_right = 1.0
	boost_label.offset_left = -260
	boost_label.offset_right = -14
	boost_label.offset_top = 56
	hud_root.add_child(boost_label)
	chasing_label = _create_label("", 17, Color.WHITE)
	chasing_label.position = Vector2(24, 102)
	hud_root.add_child(chasing_label)
	notice_label = _create_label("", 25, Color("#ffcc70"))
	notice_label.anchor_left = 0.50
	notice_label.anchor_right = 0.50
	notice_label.offset_left = -210
	notice_label.offset_right = 260
	notice_label.offset_top = 19
	hud_root.add_child(notice_label)
	var left := _make_button("◀", 0.0, 18, 154, -156, -14)
	left.button_down.connect(_turn_left_down)
	left.button_up.connect(_turn_left_up)
	var right := _make_button("▶", 0.0, 164, 300, -156, -14)
	right.button_down.connect(_turn_right_down)
	right.button_up.connect(_turn_right_up)
	var brake := _make_button("FRENO", 1.0, -338, -190, -156, -14)
	brake.button_down.connect(_brake_down)
	brake.button_up.connect(_brake_up)
	var gas := _make_button("ACCELERA", 1.0, -181, -15, -156, -14)
	gas.button_down.connect(_gas_down)
	gas.button_up.connect(_gas_up)
	var boost := _make_button("BOOST", 1.0, -181, -15, -292, -170)
	boost.button_down.connect(_boost_down)
	boost.button_up.connect(_boost_up)
	var reset_button := _make_button("↺", 0.0, 22, 92, -255, -169)
	reset_button.button_down.connect(_reset_pressed)

func _make_button(caption: String, horizontal_anchor: float, left: float, right: float, top: float, bottom: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 23)
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

func _gas_down() -> void:
	accelerating = true

func _gas_up() -> void:
	accelerating = false

func _reset_pressed() -> void:
	if racing and not finished:
		_rescue_car()

func _rescue_car() -> void:
	# Recovery is user-triggered or off-road only; never auto-steers on track.
	var progress: float = float(player["progress"])
	player_world_pos = circuit.location(progress, 0.0)
	player_world_pos.y = float(circuit.ROAD_Y) + 0.04
	player_heading = circuit.direction_yaw(progress)
	player["lane"] = 0.0
	player["speed"] = 0.0
	offroad_seconds = 0.0
	reset_count += 1


func _turn_left_down() -> void:
	turning = 1.0
func _turn_left_up() -> void:
	if turning > 0.0: turning = 0.0
func _turn_right_down() -> void:
	turning = -1.0
func _turn_right_up() -> void:
	if turning < 0.0: turning = 0.0
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
		turning = 1.0 if key.pressed else 0.0
	elif key.keycode == KEY_RIGHT or key.keycode == KEY_D:
		turning = -1.0 if key.pressed else 0.0
	elif key.keycode == KEY_DOWN or key.keycode == KEY_S:
		braking = key.pressed
	elif key.keycode == KEY_UP or key.keycode == KEY_W:
		accelerating = key.pressed
	elif key.keycode == KEY_SPACE:
		boosting = key.pressed
	elif key.keycode == KEY_R and key.pressed:
		_reset_pressed()


func _process(delta: float) -> void:
	if not racing or finished:
		return
	delta = minf(delta, 0.05)
	if start_delay > 0.0:
		start_delay = maxf(0.0, start_delay - delta)
		notice_label.text = "VIA!" if start_delay <= 0.0 else "PARTENZA: %d" % int(ceil(start_delay))
		_camera_follow(delta)
		return
	race_time += delta
	for entry in cars:
		if entry == player:
			continue
		_update_ai(entry, delta)
	_update_player(delta)
	for entry in cars:
		if entry != player:
			_position_car(entry)
	_camera_follow(delta)
	_update_hud()
	if float(player["progress"]) >= float(circuit.length) * float(LAPS):
		_finish()


func _ai_corner_target(progress: float, maximum: float) -> float:
	var target: float = maximum
	# An actual braking envelope: scan forward up to 160m and slow BEFORE corners.
	for i in range(0, 14):
		var ahead: float = float(i) * 12.0
		var v: float = float(circuit.safe_corner_speed(progress + ahead))
		var reachable: float = sqrt(v * v + 2.0 * 36.0 * ahead)
		target = minf(target, reachable)
	return target

func _update_ai(entry: Dictionary, delta: float) -> void:
	var idx: int = int(entry["index"])
	var progress: float = float(entry["progress"])
	var skill: float = _driver_pace(idx)
	# Reduce field gaps; the slowest car should not be 40km/h slower on a straight.
	var performance: float = 0.82 + 0.18 * skill
	var max_speed: float = 83.0 * performance
	var desired: float = _ai_corner_target(progress, max_speed) * (0.91 + skill * 0.09)
	var lane: float = float(entry["lane"])
	var target_lane: float = float(entry["target_lane"])
	var closest: float = 1000.0
	for other in cars:
		if other == entry:
			continue
		var gap: float = float(other["progress"]) - progress
		if gap > -13.0 and gap < 52.0 and absf(float(other["lane"]) - lane) < 3.0:
			if gap > 0.0 and gap < closest:
				closest = gap
				if gap < 32.0:
					var preferred: float = -1.0 if idx % 2 == 0 else 1.0
					var passing_lane: float = float(other["lane"]) + preferred * 3.5
					if absf(passing_lane) > 6.1:
						passing_lane = float(other["lane"]) - preferred * 3.5
					var free: bool = true
					for blocker in cars:
						if blocker == entry:
							continue
						if absf(float(blocker["progress"]) - progress) < 17.0 and absf(float(blocker["lane"]) - passing_lane) < 2.6:
							free = false
							break
					if free:
						target_lane = passing_lane
					else:
						desired = minf(desired, float(other["speed"]) + maxf(0.0, (gap - 7.0) * 0.65))
	# A controlled defensive move (max one) when the human approaches from behind.
	var player_gap: float = float(entry["progress"]) - float(player["progress"])
	if player_gap > 6.0 and player_gap < 38.0 and absf(float(player["lane"]) - lane) < 3.0:
		if not bool(entry.get("defended", false)) and absf(target_lane) < 3.2:
			target_lane = clampf(float(player["lane"]) * 0.74, -3.6, 3.6)
			entry["defended"] = true
	if closest > 48.0 and absf(target_lane) > 0.2:
		target_lane = move_toward(target_lane, 0.0, delta * 0.55)
	entry["target_lane"] = clampf(target_lane, -6.0, 6.0)
	entry["lane"] = move_toward(lane, float(entry["target_lane"]), delta * 3.0)
	var previous: float = float(entry["speed"])
	entry["speed"] = move_toward(previous, desired, delta * (35.0 if previous > desired else 18.0))
	entry["progress"] = progress + float(entry["speed"]) * delta

func _update_player(delta: float) -> void:
	var progress: float = float(player["progress"])
	var speed: float = float(player["speed"])
	var team_skill: float = _driver_pace(chosen_index)
	var max_speed: float = 83.0 * (0.82 + 0.18 * team_skill)
	var boost_active: bool = accelerating and boosting and not braking and boost_meter >= 1.0
	if boost_active:
		max_speed += 6.0
		boost_meter = maxf(0.0, boost_meter - delta * 26.0)
	else:
		boost_meter = minf(100.0, boost_meter + delta * 7.5)
	# Physics-lite controls: no throttle input -> car coasts, then slows.
	if braking:
		speed = maxf(0.0, speed - 44.0 * delta)
	elif accelerating:
		var acceleration: float = 19.0 * (0.60 + 0.40 * (1.0 - clampf(speed / max_speed, 0.0, 1.0)))
		if boost_active:
			acceleration += 5.5
		speed = minf(max_speed, speed + acceleration * delta)
	else:
		speed = maxf(0.0, speed - (2.0 + speed * 0.038) * delta)
	# Actual unassisted heading: the track curve NEVER sets player rotation.
	# Steering is speed-sensitive, easy to handle at low speed, incapable of
	# taking a 30m radius hairpin flat-out at 300 km/h.
	if speed > 0.6:
		var yaw_rate: float = lerpf(1.80, 0.78, clampf(speed / 85.0, 0.0, 1.0))
		player_heading += turning * yaw_rate * delta
	var lane: float = float(circuit.lane_of(player_world_pos, progress))
	# No ghosting through defenders: approaching cars constrain forward speed.
	for other in cars:
		if other == player:
			continue
		var gap: float = float(other["progress"]) - progress
		if gap > -0.5 and gap < 13.0 and absf(float(other["lane"]) - lane) < 2.45:
			speed = minf(speed, float(other["speed"]) + maxf(0.0, (gap - 6.2) / maxf(delta, 0.012)))
			speed = maxf(speed, 0.0)
	var direction := Vector3(-sin(player_heading), 0.0, -cos(player_heading))
	var next_pos: Vector3 = player_world_pos + direction * speed * delta
	var predicted_progress: float = float(circuit.nearest_progress(next_pos, progress))
	var max_step: float = speed * delta * 1.4 + 1.0
	predicted_progress = clampf(predicted_progress, progress - max_step, progress + max_step)
	player_world_pos = next_pos
	player["progress"] = predicted_progress
	lane = float(circuit.lane_of(player_world_pos, predicted_progress))
	player["lane"] = lane
	if absf(lane) > 9.8:
		# Grass/runoff incurs a severe penalty; no auto-correction of steering.
		speed = maxf(0.0, speed - 42.0 * delta)
		offroad_seconds += delta
	else:
		offroad_seconds = maxf(0.0, offroad_seconds - delta * 4.0)
	if absf(lane) > 23.0 or offroad_seconds > 2.5:
		_rescue_car()
		return
	player["speed"] = speed
	var node: Node3D = player["node"]
	node.position = player_world_pos
	node.rotation.y = player_heading


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
	if offroad_seconds > 0.1:
		notice_label.text = "FUORI PISTA! RALLENTA"
	else:
		notice_label.text = ""
	if reset_count > 0:
		chasing_label.text += "  ·  RIENTRI: %d" % reset_count

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
