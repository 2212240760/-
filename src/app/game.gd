extends Node

const SaveGame = preload("res://src/systems/save/save_game.gd")
const SaveIO = preload("res://src/systems/save/save_io.gd")
const SaveMigrations = preload("res://src/systems/save/save_migrations.gd")
const Inventory = preload("res://src/systems/inventory/inventory.gd")
const Codex = preload("res://src/systems/progress/codex.gd")
const Recipes = preload("res://src/systems/inventory/recipes.gd")
const BaseManager = preload("res://src/systems/base/base_manager.gd")
const ProductionJob = preload("res://src/systems/base/jobs.gd")
const ItemStack = preload("res://src/systems/inventory/item_stack.gd")
const ItemDefs = preload("res://src/systems/inventory/item_defs.gd")
const DataRegistry = preload("res://src/systems/data/data_registry.gd")
const PetSpecies = preload("res://src/domain/pet_species.gd")
const DropTable = preload("res://src/systems/loot/drop_table.gd")
const EncounterTable = preload("res://src/systems/overworld/encounter_table.gd")

var save: SaveGame
var inventory: Inventory
var codex: Codex
var recipes: Recipes
var base: BaseManager
var item_defs: ItemDefs
var species_defs: Dictionary = {}
var skill_defs: Dictionary = {}
var rng := RandomNumberGenerator.new()
var current_region_id := "region_01"
var current_encounter_species_id := ""

func _ready() -> void:
	rng.randomize()

func new_game() -> void:
	save = SaveGame.new()
	save.inventory = {"ball_basic": 3}
	save.base_state = {
		"inventory": {"ore": 6},
		"jobs": [],
		"buildings": {"forge": {"building_id": "forge", "level": 1, "helpers": 0}},
		"unlocked_recipes": {"smelt_ingot": true}
	}
	_init_runtime_from_save()

func load_game(slot := "slot1") -> bool:
	var io = SaveIO.new()
	var raw = io.read(slot)
	if typeof(raw) != TYPE_DICTIONARY or raw.has("_error"):
		return false
	var upgraded = SaveMigrations.upgrade(raw)
	save = SaveGame.from_dict(upgraded)
	_init_runtime_from_save()
	return true

func save_game(slot := "slot1") -> bool:
	if save == null:
		return false
	save.inventory = inventory.to_dict()
	save.codex = {"discovered": codex.discovered.duplicate(true), "captured": codex.captured.duplicate(true)}
	save.base_state = {
		"inventory": base.inventory.duplicate(true),
		"jobs": _serialize_jobs(base.jobs),
		"buildings": _serialize_buildings(base.buildings),
		"unlocked_recipes": base.unlocked_recipes.duplicate(true)
	}
	var io = SaveIO.new()
	return io.write(save, slot)

func goto_overworld() -> void:
	get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")

func goto_battle() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func goto_base() -> void:
	get_tree().change_scene_to_file("res://scenes/base/base.tscn")

func _init_runtime_from_save() -> void:
	inventory = Inventory.new(save.inventory)
	codex = Codex.new()
	codex.discovered = Dictionary(save.codex.get("discovered", {})).duplicate(true)
	codex.captured = Dictionary(save.codex.get("captured", {})).duplicate(true)

	recipes = Recipes.new()
	recipes.load_from_path("res://data/recipes/sample_recipes.json")

	base = BaseManager.new(recipes)
	base.inventory = Dictionary(save.base_state.get("inventory", {})).duplicate(true)
	base.jobs = _deserialize_jobs(save.base_state.get("jobs", []))
	base.unlocked_recipes = Dictionary(save.base_state.get("unlocked_recipes", {})).duplicate(true)
	_deserialize_buildings(base, save.base_state.get("buildings", {}))

	item_defs = ItemDefs.new()
	item_defs.load_from_paths(["res://data/items/sample_capture_items.json"])

	var reg = DataRegistry.new()
	var raw_species = reg.load_json("res://data/pets/species.json")
	species_defs.clear()
	if typeof(raw_species) == TYPE_ARRAY:
		for e in raw_species:
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var sp = PetSpecies.from_dict(e)
			if sp != null and sp.id != "":
				species_defs[sp.id] = sp

	var raw_skills = reg.load_json("res://data/skills/sample_skills.json")
	if typeof(raw_skills) == TYPE_ARRAY:
		for e in raw_skills:
			if typeof(e) == TYPE_DICTIONARY:
				var d: Dictionary = e
				var sid = str(d.get("id", ""))
				if sid != "":
					skill_defs[sid] = d.duplicate(true)

func _serialize_jobs(jobs: Array) -> Array:
	var out: Array = []
	for j in jobs:
		if j == null:
			continue
		out.append({
			"recipe_id": str(j.recipe_id),
			"building_key": str(j.building_key),
			"qty": int(j.qty),
			"ticks_left": int(j.ticks_left),
			"outputs": _serialize_stacks(j.outputs)
		})
	return out

func _deserialize_jobs(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for e in raw:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = e
		var rid = str(d.get("recipe_id", ""))
		if rid == "":
			continue
		var qty = int(d.get("qty", 1))
		var ticks_left = int(d.get("ticks_left", 0))
		var outputs = _deserialize_stacks(d.get("outputs", []))
		var building_key = str(d.get("building_key", ""))
		var j = ProductionJob.new(rid, qty, ticks_left, outputs, building_key)
		j.ticks_left = ticks_left
		out.append(j)
	return out

func _serialize_stacks(stacks: Array) -> Array:
	var out: Array = []
	for s in stacks:
		if s == null:
			continue
		out.append({"id": str(s.id), "qty": int(s.qty)})
	return out

func _deserialize_stacks(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for e in raw:
		if typeof(e) == TYPE_DICTIONARY:
			var s = ItemStack.from_dict(e)
			if s.is_valid():
				out.append(s)
	return out

func _serialize_buildings(raw: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in raw.keys():
		var b = raw[k]
		if b == null:
			continue
		var helpers = 0
		if b.has("assigned_helpers"):
			helpers = int(b.assigned_helpers.size())
		out[str(k)] = {
			"building_id": str(b.building_id),
			"level": int(b.level),
			"helpers": helpers
		}
	return out

func _deserialize_buildings(bm: BaseManager, raw: Variant) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for k in raw.keys():
		var d = raw[k]
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var bd: Dictionary = d
		var bid = str(bd.get("building_id", ""))
		var lvl = int(bd.get("level", 1))
		var helpers = int(bd.get("helpers", 0))
		bm.ensure_building(str(k), bid, lvl, helpers)

func load_region_drop_table(region_id: String) -> DropTable:
	var dt = DropTable.new()
	var path = "res://data/drop_tables/%s.json" % region_id
	dt.load_from_path(path)
	return dt

func roll_encounter_species_id(region_id: String) -> String:
	var et = EncounterTable.new()
	var path = "res://data/regions/%s.json" % region_id
	if not et.load_from_path(path):
		return ""
	return et.pick(rng)
