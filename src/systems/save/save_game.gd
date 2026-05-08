extends RefCounted

class_name SaveGame

const VERSION := 1

var player_party := []
var codex := {"discovered": {}, "captured": {}}
var inventory := {}
var base_state := {}
var progress := {"chapter_id": "chapter_01", "unlocked_regions": ["region_01"]}

func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"player_party": player_party,
		"codex": codex,
		"inventory": inventory,
		"base_state": base_state,
		"progress": progress
	}

static func from_dict(d: Dictionary) -> SaveGame:
	var s := SaveGame.new()
	s.player_party = d.get("player_party", [])
	s.codex = d.get("codex", s.codex)
	s.inventory = d.get("inventory", {})
	s.base_state = d.get("base_state", {})
	s.progress = d.get("progress", s.progress)
	return s
