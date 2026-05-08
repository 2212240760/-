extends RefCounted

class_name PetSpecies

var id := ""
var name := ""
var rarity := ""
var elements: Array = []
var base_stats: Dictionary = {}
var learnset: Array = []
var possible_traits: Array = []

static func from_dict(d: Dictionary) -> PetSpecies:
	var s := PetSpecies.new()
	s.id = d.get("id", "")
	s.name = d.get("name", "")
	s.rarity = d.get("rarity", "")
	s.elements = d.get("elements", [])
	s.base_stats = d.get("base_stats", {})
	s.learnset = d.get("learnset", [])
	s.possible_traits = d.get("possible_traits", [])
	return s
