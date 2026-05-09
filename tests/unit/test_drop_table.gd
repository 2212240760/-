extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const DropTable = preload("res://src/systems/loot/drop_table.gd")

func run() -> bool:
	var t := DropTable.new()
	var ok := true
	ok = ok and Asserts.ok(t.load_from_path("res://data/drop_tables/sample_region_01.json"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var drop: Dictionary = t.roll(rng)
	var id := str(drop.get("id", ""))
	var qty := int(drop.get("qty", 0))
	ok = ok and Asserts.ok(id == "ore" or id == "ball_basic" or id == "ingot")
	ok = ok and Asserts.ok(qty >= 1 and qty <= 3)
	return ok

