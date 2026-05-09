extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const DataRegistry = preload("res://src/systems/data/data_registry.gd")

func run() -> bool:
	var reg := DataRegistry.new()
	var data = reg.load_json("res://data/pets/species.json")
	var ok := true
	ok = ok and Asserts.ok(typeof(data) == TYPE_ARRAY)
	if typeof(data) != TYPE_ARRAY:
		return false
	ok = ok and Asserts.eq(int(data.size()), 10)
	return ok

