extends RefCounted

class_name Inventory

var items: Dictionary = {}

func _init(from_dict := {}):
	if typeof(from_dict) == TYPE_DICTIONARY:
		items = Dictionary(from_dict).duplicate(true)

func get_item(item_id: String) -> int:
	return int(items.get(item_id, 0))

func set_item(item_id: String, amount: int) -> void:
	var v := max(0, int(amount))
	if v == 0:
		items.erase(item_id)
	else:
		items[item_id] = v

func add_item(item_id: String, delta: int) -> void:
	set_item(item_id, get_item(item_id) + int(delta))

func to_dict() -> Dictionary:
	return items.duplicate(true)

