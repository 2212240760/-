extends RefCounted

class_name DropTable

const DataRegistry = preload("res://src/systems/data/data_registry.gd")

var entries: Array = []

func load_from_path(path: String) -> bool:
	entries.clear()
	var reg := DataRegistry.new()
	var data = reg.load_json(path)
	if typeof(data) != TYPE_ARRAY:
		return false
	for e in data:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = e
		var id := str(d.get("id", ""))
		if id == "":
			continue
		var weight := float(d.get("weight", 0.0))
		if weight <= 0.0:
			continue
		entries.append(d.duplicate(true))
	return entries.size() > 0

func roll(rng: RandomNumberGenerator) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
	if entries.size() == 0:
		return {}
	var total := 0.0
	for e in entries:
		total += float(e.get("weight", 0.0))
	if total <= 0.0:
		return {}
	var t := rng.randf() * total
	var acc := 0.0
	for e in entries:
		acc += float(e.get("weight", 0.0))
		if t <= acc:
			var id := str(e.get("id", ""))
			var min_qty := int(e.get("min", 1))
			var max_qty := int(e.get("max", min_qty))
			var qty := min_qty if max_qty <= min_qty else rng.randi_range(min_qty, max_qty)
			return {"id": id, "qty": qty}
	var last: Dictionary = entries[entries.size() - 1]
	return {"id": str(last.get("id", "")), "qty": int(last.get("min", 1))}

