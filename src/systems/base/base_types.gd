extends RefCounted

class_name BuildingInstance

var building_id := ""
var level := 1
var assigned_helpers := []

func efficiency() -> float:
	return 1.0 + 0.1 * float(assigned_helpers.size()) + 0.2 * float(level - 1)
