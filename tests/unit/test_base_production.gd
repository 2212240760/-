extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const Recipes = preload("res://src/systems/inventory/recipes.gd")
const BaseManager = preload("res://src/systems/base/base_manager.gd")

func run() -> bool:
	var defs := Recipes.new()
	var loaded := defs.load_from_path("res://data/recipes/sample_recipes.json")

	var ok := true
	ok = ok and Asserts.ok(loaded)
	ok = ok and Asserts.ok(defs.get_recipe("smelt_ingot").size() > 0)

	var base := BaseManager.new(defs)
	base.set_item("ore", 10)

	ok = ok and Asserts.ok(not base.start_job("craft_sword", 1))
	ok = ok and Asserts.ok(base.start_job("smelt_ingot", 2))
	ok = ok and Asserts.eq(base.get_item("ore"), 6)

	base.tick(5)
	ok = ok and Asserts.eq(base.get_item("ingot"), 0)
	ok = ok and Asserts.eq(base.jobs.size(), 1)

	base.tick(1)
	ok = ok and Asserts.eq(base.get_item("ingot"), 2)
	ok = ok and Asserts.eq(base.jobs.size(), 0)

	ok = ok and Asserts.ok(base.start_job("craft_sword", 1))
	ok = ok and Asserts.eq(base.get_item("ingot"), 0)
	base.tick(5)
	ok = ok and Asserts.eq(base.get_item("sword"), 1)
	return ok
