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
	base.set_item("ingot", 10)
	base.unlocked_recipes = {"smelt_ingot": true}
	ok = ok and Asserts.ok(not base.start_job("craft_sword", 1))
	base.unlocked_recipes["craft_sword"] = true
	ok = ok and Asserts.ok(base.start_job("craft_sword", 1))
	return ok

