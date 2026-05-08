extends RefCounted

class_name Codex

var discovered: Dictionary = {}
var captured: Dictionary = {}

func mark_discovered(species_id: String) -> void:
	discovered[species_id] = true

func mark_captured(species_id: String) -> void:
	mark_discovered(species_id)
	captured[species_id] = int(captured.get(species_id, 0)) + 1

func captured_count(species_id: String) -> int:
	return int(captured.get(species_id, 0))
