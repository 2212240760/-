extends RefCounted

class_name ItemDefs

const DataRegistry = preload("res://src/systems/data/data_registry.gd")

var items: Dictionary = {}

func load_from_paths(paths: Array[String]) -> bool:
	items.clear()
	var reg := DataRegistry.new()
	for p in paths:
		var data = reg.load_json(p)
		if typeof(data) == TYPE_ARRAY:
			for e in data:
				if typeof(e) != TYPE_DICTIONARY:
					continue
				var d: Dictionary = e
				var id := str(d.get("id", ""))
				if id == "":
					continue
				items[id] = d.duplicate(true)
	return items.size() > 0

func get_def(id: String) -> Dictionary:
	if items.has(id):
		return items[id]
	return {}

func get_name(id: String) -> String:
	return str(get_def(id).get("name", id))

func get_power(id: String) -> float:
	return float(get_def(id).get("power", 0.0))

