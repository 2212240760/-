extends RefCounted

class_name EncounterTable

const DataRegistry = preload("res://src/systems/data/data_registry.gd")

var entries: Array = []

func load_from_path(path: String) -> bool:
	var reg = DataRegistry.new()
	var data = reg.load_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return load_from_dict(data)

func load_from_dict(d: Dictionary) -> bool:
	entries.clear()
	var raw = d.get("encounters", [])
	if typeof(raw) != TYPE_ARRAY:
		return false
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var ed: Dictionary = e
		var sid := str(ed.get("species_id", ""))
		var w := int(ed.get("weight", 0))
		if sid == "" or w <= 0:
			continue
		entries.append({"species_id": sid, "weight": w})
	return entries.size() > 0

func pick_with_roll(roll: float) -> String:
	if entries.is_empty():
		return ""
	var total := 0
	for e in entries:
		total += int(e.get("weight", 0))
	if total <= 0:
		return ""
	var r := clampf(float(roll), 0.0, 0.999999) * float(total)
	var acc := 0.0
	for e in entries:
		acc += float(int(e.get("weight", 0)))
		if r < acc:
			return str(e.get("species_id", ""))
	return str(entries[entries.size() - 1].get("species_id", ""))

func pick(rng: RandomNumberGenerator) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
	return pick_with_roll(rng.randf())

