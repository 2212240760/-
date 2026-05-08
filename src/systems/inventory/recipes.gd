extends RefCounted

class_name Recipes

const DataRegistry = preload("res://src/systems/data/data_registry.gd")
const Validators = preload("res://src/systems/data/validators.gd")
const ItemStack = preload("res://src/systems/inventory/item_stack.gd")

var _recipes: Dictionary = {}
var _errors: Array = []

func errors() -> Array:
	return _errors

func load_from_path(path: String) -> bool:
	_recipes.clear()
	_errors.clear()

	var reg := DataRegistry.new()
	var data = reg.load_json(path)
	if typeof(data) != TYPE_ARRAY:
		return false

	for i in range(data.size()):
		var raw = data[i]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = raw

		var errs: Array = []
		errs.append_array(Validators.require_keys(r, ["id", "inputs", "outputs", "ticks"], path))
		errs.append_array(Validators.require_type(r, "id", TYPE_STRING, path))
		errs.append_array(Validators.require_type(r, "inputs", TYPE_ARRAY, path))
		errs.append_array(Validators.require_type(r, "outputs", TYPE_ARRAY, path))
		var ticks_t := typeof(r.get("ticks", 0))
		if ticks_t != TYPE_INT and ticks_t != TYPE_FLOAT:
			errs.append_array(Validators.require_type(r, "ticks", TYPE_INT, path))
		if errs.size() > 0:
			_errors.append_array(errs)
			continue

		var rid := str(r.get("id", ""))
		if rid == "":
			continue

		var ticks := int(r.get("ticks", 0))
		if ticks <= 0:
			continue

		var parsed_inputs := _parse_stacks(r.get("inputs", []))
		var parsed_outputs := _parse_stacks(r.get("outputs", []))
		if parsed_inputs.size() == 0 or parsed_outputs.size() == 0:
			continue

		_recipes[rid] = {
			"id": rid,
			"name": str(r.get("name", "")),
			"ticks": ticks,
			"inputs": parsed_inputs,
			"outputs": parsed_outputs
		}

	return _recipes.size() > 0

func get_recipe(id: String) -> Dictionary:
	if _recipes.has(id):
		return _recipes[id]
	return {}

func _parse_stacks(raw: Array) -> Array:
	var out: Array = []
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var s := ItemStack.from_dict(e)
		if s.is_valid():
			out.append(s)
	return out
