extends RefCounted

class_name PetInstance

var species_id := ""
var level := 1
var exp := 0
var trait_ids: Array[String] = []
var equipped_skills: Array[String] = []
var current_hp := 1

func to_save_dict() -> Dictionary:
	return {
		"species_id": species_id,
		"level": level,
		"exp": exp,
		"trait_ids": trait_ids,
		"equipped_skills": equipped_skills,
		"current_hp": current_hp
	}

static func from_save_dict(d: Dictionary):
	var p = (load("res://src/domain/pet_instance.gd") as Script).new()
	p.species_id = d.get("species_id", "")
	p.level = int(d.get("level", 1))
	p.exp = int(d.get("exp", 0))
	p.trait_ids = d.get("trait_ids", [])
	p.equipped_skills = d.get("equipped_skills", [])
	p.current_hp = int(d.get("current_hp", 1))
	return p
