extends RefCounted

class_name ItemStack

var id := ""
var qty := 0

func _init(_id := "", _qty := 0):
	id = _id
	qty = int(_qty)

static func from_dict(d: Dictionary):
	var sid := str(d.get("id", ""))
	var sqty := int(d.get("qty", 0))
	return (load("res://src/systems/inventory/item_stack.gd") as Script).new(sid, sqty)

func scaled(mult: int):
	return (get_script() as Script).new(id, qty * int(mult))

func is_valid() -> bool:
	return id != "" and qty > 0
