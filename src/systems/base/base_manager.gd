extends RefCounted

class_name BaseManager

const ProductionJob = preload("res://src/systems/base/jobs.gd")
const ItemStack = preload("res://src/systems/inventory/item_stack.gd")
const BuildingInstance = preload("res://src/systems/base/base_types.gd")

var inventory: Dictionary = {}
var jobs: Array = []
var recipes
var buildings: Dictionary = {}

func _init(_recipes = null):
	recipes = _recipes

func get_item(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func set_item(item_id: String, amount: int):
	var v := max(0, int(amount))
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

func start_job(recipe_id: String, qty := 1) -> bool:
	if recipes == null:
		return false
	var q := max(1, int(qty))
	var recipe = recipes.get_recipe(recipe_id)
	if typeof(recipe) != TYPE_DICTIONARY or recipe.is_empty():
		return false

	var inputs: Array = recipe.get("inputs", [])
	var outputs: Array = recipe.get("outputs", [])
	var ticks_per := int(recipe.get("ticks", 0))
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

	var job := ProductionJob.new(recipe_id, q, ticks_per * q, scaled_outputs)
	jobs.append(job)
	return true

func tick(steps := 1) -> int:
	var completed := 0
	var s := max(1, int(steps))
	for i in range(jobs.size() - 1, -1, -1):
		var job = jobs[i]
		if job.tick(s):
			for out_stack in job.outputs:
				add_item(out_stack.id, out_stack.qty)
			jobs.remove_at(i)
			completed += 1
	return completed
