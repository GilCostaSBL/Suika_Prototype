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

	# Keyboard: holding move_right shifts the dropper; the drop action drops a fruit.
	var start_x: float = main.drop_x
	Input.action_press("move_right")
	await _wait_physics(30)
	Input.action_release("move_right")
	_expect(main.drop_x > start_x, "move_right shifts the dropper (%.0f -> %.0f)" % [start_x, main.drop_x])
	var count_before := _tiers(main).size()
	Input.action_press("drop")
	await _wait_physics(2)
	Input.action_release("drop")
	_expect(_tiers(main).size() == count_before + 1, "drop action spawns a fruit")
	await _wait_physics(240)

	# Bounce scales from small (bouncy) to large (dull).
	var cherry: Fruit = main._spawn_fruit(0, Vector2(200, 500))
	var melon: Fruit = main._spawn_fruit(10, Vector2(400, 500))
	_expect(is_equal_approx(cherry.physics_material_override.bounce, main.balance.bounce_smallest), "cherry uses bounce_smallest")
	_expect(is_equal_approx(melon.physics_material_override.bounce, main.balance.bounce_largest), "watermelon uses bounce_largest")
	cherry.queue_free()
	melon.queue_free()
	await physics_frame

	# Merge pop: a close neighbour is pushed away, a far one is not.
	var source: Fruit = main._spawn_fruit(1, Vector2(200, 500))
	var near: Fruit = main._spawn_fruit(0, Vector2(260, 500))
	var far: Fruit = main._spawn_fruit(0, Vector2(560, 500))
	main.pop_neighbors(source)
	await physics_frame
	_expect(near.linear_velocity.x > 20.0, "merge pop pushes a close fruit away (vx %.0f)" % near.linear_velocity.x)
	_expect(absf(far.linear_velocity.x) < 1.0, "merge pop leaves far fruit alone (vx %.1f)" % far.linear_velocity.x)
	for f in [source, near, far]:
		f.queue_free()
	await physics_frame

	# Coins: one per points_per_coin (50) passed.
	main._add_score(300 - main.score)
	_expect(main.coins == 6, "300 points gives 6 coins (got %d)" % main.coins)

	# Fruit Slot: pay to stash the current fruit, release it for free.
	var cur: int = main.current_tier
	var nxt: int = main.next_tier
	_expect(main.activate_ability(0), "slot stores the current fruit")
	_expect(main.held_tier == cur and main.current_tier == nxt, "held fruit is stored and queue advances")
	_expect(main.coins == 1, "slot costs 5 (coins %d)" % main.coins)
	_expect(main.activate_ability(0), "slot releases the stored fruit")
	_expect(main.held_tier == -1 and main.current_tier == cur and main.next_tier == nxt, "released fruit is back in the dropper")
	_expect(main.coins == 1, "release is free (coins %d)" % main.coins)

	# Fruit Swap: refuses without coins, otherwise rerolls the next fruit.
	_expect(not main.activate_ability(1), "swap refused with 1 coin")
	main._add_score(1000 - main.score)
	var old_next: int = main.next_tier
	_expect(main.activate_ability(1), "swap fires with enough coins")
	_expect(main.next_tier != old_next, "swap changes the next fruit (%d -> %d)" % [old_next, main.next_tier])
	_expect(main.coins == 5, "swap costs 10 (coins %d)" % main.coins)

	# Shake Up: everything stays inside the jar and the world is restored afterwards.
	for i in 6:
		main._spawn_fruit(i % 5, Vector2(120 + i * 90, 900))
	await _wait_physics(120)
	main._add_score(2500 - main.score)
	_expect(main.activate_ability(2), "shake up fires with 35 coins")
	_expect(not main.activate_ability(0), "abilities locked during shake up")
	# After the first 90° turn the old right wall is the floor: fruit should have settled against it.
	var frames := 0
	while main.shake_up.flips_done < 1 and frames < 1000:
		await physics_frame
		frames += 1
	var mean_x := _mean_fruit_pos(main).x
	_expect(mean_x > 450.0, "fruit settles on the new floor after a 90° turn (mean x %.0f, jar center 360)" % mean_x)
	while main.shake_up.active and frames < 3000:
		await physics_frame
		frames += 1
	_expect(not main.shake_up.active, "shake up finishes (%.1f s)" % (frames / 120.0))
	_expect(main.shake_up.flips_done == 4, "jar made 4 turns (got %d)" % main.shake_up.flips_done)
	var space: RID = main.get_world_2d().space
	var gravity: Vector2 = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR)
	_expect(gravity.is_equal_approx(Vector2.DOWN), "gravity restored (got %s)" % gravity)
	var strength: float = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY)
	_expect(is_equal_approx(strength, 980.0), "gravity strength restored (got %.0f)" % strength)
	_expect(main.get_viewport().canvas_transform == Transform2D.IDENTITY, "view restored")
	var escaped := 0
	for child in main.get_node("Fruits").get_children():
		if child is Fruit and not Rect2(55, 250, 610, 960).has_point(child.global_position):
			escaped += 1
	_expect(escaped == 0, "no fruit escaped the jar (%d out)" % escaped)
	_expect(not main.is_over, "shake up didn't end the game")

	# Debug key grants coins (the editor binary is a debug build).
	var coins_before: int = main.coins
	Input.action_press("debug_coins")
	await _wait_physics(2)
	Input.action_release("debug_coins")
	_expect(main.coins == coins_before + main.balance.debug_coin_grant, "F1 grants debug coins (%d -> %d)" % [coins_before, main.coins])

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


func _mean_fruit_pos(main: Node) -> Vector2:
	var total := Vector2.ZERO
	var count := 0
	for child in main.get_node("Fruits").get_children():
		if child is Fruit and not child.is_queued_for_deletion():
			total += child.global_position
			count += 1
	return total / maxi(count, 1)


func _expect(ok: bool, message: String) -> void:
	if ok:
		print("ok   " + message)
	else:
		failures.append(message)
