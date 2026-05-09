extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")

func run() -> bool:
	var script = load("res://src/systems/overworld/encounter_table.gd")
	var ok := true
	ok = ok and Asserts.ok(script != null)
	if script == null:
		return false
	var table = script.new()
	ok = ok and Asserts.ok(table.load_from_path("res://data/regions/region_01.json"))
	if not table.load_from_path("res://data/regions/region_01.json"):
		return false
	ok = ok and Asserts.eq(str(table.pick_with_roll(0.0)), "slime_001")
	ok = ok and Asserts.eq(str(table.pick_with_roll(0.99)), "dragon_001")
	return ok

