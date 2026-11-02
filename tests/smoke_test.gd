extends SceneTree

## Headless smoke test for the core loop. Run with:
## <godot> --headless --path . -s res://tests/smoke_test.gd
## Exits with code 1 if any check fails.

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame

	# Two cherries landing on each other merge into one strawberry.
	main._spawn_fruit(0, Vector2(360, 1100))
	main._spawn_fruit(0, Vector2(360, 1000))
	await _wait_physics(240)
	_expect(main.score == 1, "cherry merge scores 1 (got %d)" % main.score)
	_expect(_tiers(main) == [1], "cherries become one strawberry (got %s)" % [_tiers(main)])

	# Two watermelons vanish and score the top tier.
	main._spawn_fruit(10, Vector2(360, 1000))
	main._spawn_fruit(10, Vector2(360, 600))
	await _wait_physics(240)
	_expect(main.score == 1 + FruitData.merge_score(10), "watermelon merge adds 66, total 67 (got %d)" % main.score)
	_expect(_tiers(main) == [1], "watermelons vanish (got %s)" % [_tiers(main)])
	_expect(not main.is_over, "no game over yet")

	# A settled fruit held above the danger line ends the game.
	var stuck: Fruit = main._spawn_fruit(0, Vector2(120, 330))
	stuck.freeze = true
	stuck.age = 5.0
	await _wait_physics(int(main.GAME_OVER_TIME * 120) + 30)
	_expect(main.is_over, "fruit above danger line triggers game over")

	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL: " + f)
		quit(1)


func _wait_physics(frames: int) -> void:
	for i in frames:
		await physics_frame


func _tiers(main: Node) -> Array:
	var result := []
	for child in main.get_node("Fruits").get_children():
		if child is Fruit and not child.is_queued_for_deletion():
			result.append(child.tier)
	result.sort()
	return result


func _expect(ok: bool, message: String) -> void:
	if ok:
		print("ok   " + message)
	else:
		failures.append(message)
