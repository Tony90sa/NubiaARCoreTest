extends SceneTree

# Test automatico di avvio scena e guida: non basta un export APK valido.
func _initialize() -> void:
	call_deferred("_exercise")

func _exercise() -> void:
	var scene: PackedScene = load("res://Game.tscn")
	if scene == null:
		push_error("Game scene not found")
		quit(1)
		return
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.call("_start_race")
	var cars: Array = game.get("cars")
	if cars.size() != 22:
		push_error("Wrong grid size")
		quit(2)
		return
	var player: Dictionary = game.get("player")
	var node: Node3D = player["node"]
	if node == null:
		push_error("No player car")
		quit(3)
		return
	var initial_heading: float = float(game.get("player_heading"))
	var circuit: Node3D = game.get("circuit")
	if float(circuit.get("length")) < 1400.0:
		push_error("Circuit too short")
		quit(4)
		return
	game.set("start_delay", 0.0)
	game.set("accelerating", true)
	game.set("turning", 1.0)
	for i in range(35):
		game.call("_update_player", 0.0166667)
	if float(player["speed"]) < 3.0:
		push_error("Accelerator does not work")
		quit(5)
		return
	if absf(float(game.get("player_heading")) - initial_heading) < 0.015:
		push_error("Steering does not rotate car")
		quit(6)
		return
	var speed_before: float = float(player["speed"])
	game.set("accelerating", false)
	game.set("braking", true)
	for i in range(15):
		game.call("_update_player", 0.0166667)
	if float(player["speed"]) >= speed_before:
		push_error("Manual brake does not slow car")
		quit(7)
		return
	print("GRID26_SMOKE_PASS grid=22 circuit=%.0fm throttle/steer/brake OK" % float(circuit.get("length")))
	quit(0)
