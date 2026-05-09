extends RefCounted

class_name BaseManager

const ProductionJob = preload("res://src/systems/base/jobs.gd")
const ItemStack = preload("res://src/systems/inventory/item_stack.gd")
const BuildingInstance = preload("res://src/systems/base/base_types.gd")

var inventory: Dictionary = {}
var jobs: Array = []
var recipes
var buildings: Dictionary = {}
var unlocked_recipes: Dictionary = {}

func _init(_recipes = null):
	recipes = _recipes

func ensure_building(key: String, building_id: String, level: int, helpers: int):
	var k = str(key)
	if k == "":
		return null
	var inst = buildings.get(k, null)
	if inst == null:
		inst = BuildingInstance.new()
	inst.building_id = str(building_id)
	inst.level = max(1, int(level))
	inst.assigned_helpers = []
	for _i in range(max(0, int(helpers))):
		inst.assigned_helpers.append(true)
	buildings[k] = inst
	return inst

func get_item(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func set_item(item_id: String, amount: int):
	var v = max(0, int(amount))
	if v == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = v

func add_item(item_id: String, delta: int):
	set_item(item_id, get_item(item_id) + int(delta))

func can_afford(stacks: Array) -> bool:
	for s in stacks:
		if s == null:
			return false
		if get_item(s.id) < int(s.qty):
			return false
	return true

func _apply_delta(stacks: Array, mult: int, sign: int):
	for s in stacks:
		add_item(s.id, sign * int(s.qty) * int(mult))

func start_job(recipe_id: String, qty := 1, building_key := "") -> bool:
	if recipes == null:
		return false
	var q = max(1, int(qty))
	if not unlocked_recipes.is_empty() and not unlocked_recipes.has(recipe_id):
		return false
	var recipe = recipes.get_recipe(recipe_id)
	if typeof(recipe) != TYPE_DICTIONARY or recipe.is_empty():
		return false

	var inputs: Array = recipe.get("inputs", [])
	var outputs: Array = recipe.get("outputs", [])
	var ticks_per = int(recipe.get("ticks", 0))
	if ticks_per <= 0:
		return false

	var scaled_inputs: Array = []
	for s in inputs:
		scaled_inputs.append(s.scaled(q))
	if not can_afford(scaled_inputs):
		return false

	_apply_delta(inputs, q, -1)

	var scaled_outputs: Array = []
	for s in outputs:
		scaled_outputs.append(s.scaled(q))

	var ticks_total = ticks_per * q
	var bkey = str(building_key)
	if bkey != "" and buildings.has(bkey):
		var b = buildings[bkey]
		if b != null and b.has_method("efficiency"):
			var eff = float(b.efficiency())
			if eff > 0.0:
				ticks_total = int(ceil(float(ticks_total) / eff))

	var job = ProductionJob.new(recipe_id, q, ticks_total, scaled_outputs, bkey)
	jobs.append(job)
	return true

func tick(steps := 1) -> int:
	var completed = 0
	var s = max(1, int(steps))
	for i in range(jobs.size() - 1, -1, -1):
		var job = jobs[i]
		if job.tick(s):
			for out_stack in job.outputs:
				add_item(out_stack.id, out_stack.qty)
			jobs.remove_at(i)
			completed += 1
	return completed
