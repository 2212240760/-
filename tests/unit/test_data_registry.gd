extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const DataRegistry = preload("res://src/systems/data/data_registry.gd")
const Validators = preload("res://src/systems/data/validators.gd")

func run() -> bool:
	var reg := DataRegistry.new()
	var data = reg.load_json("res://data/pets/sample_species.json")
	var ok := true
	ok = ok and Asserts.eq(typeof(data), TYPE_DICTIONARY)
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var d: Dictionary = data
	ok = ok and Asserts.eq(d.get("id", ""), "slime_001")
	var errors: Array = []
	errors.append_array(Validators.require_keys(d, ["id", "name", "rarity", "elements", "base_stats"], "sample_species"))
	ok = ok and Asserts.eq(errors.size(), 0)
	return ok
