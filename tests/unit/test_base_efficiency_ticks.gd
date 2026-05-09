extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const Recipes = preload("res://src/systems/inventory/recipes.gd")
const BaseManager = preload("res://src/systems/base/base_manager.gd")

func run() -> bool:
	var defs := Recipes.new()
	var ok := true
	ok = ok and Asserts.ok(defs.load_from_path("res://data/recipes/sample_recipes.json"))
	var base := BaseManager.new(defs)
	base.set_item("ore", 10)
	base.ensure_building("forge", "forge", 2, 4)
	ok = ok and Asserts.ok(base.start_job("smelt_ingot", 2, "forge"))
	ok = ok and Asserts.eq(int(base.jobs[0].ticks_left), 4)
	return ok

