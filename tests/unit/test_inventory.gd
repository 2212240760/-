extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const Inventory = preload("res://src/systems/inventory/inventory.gd")

func run() -> bool:
	var inv := Inventory.new({"ore": 2})
	var ok := true
	ok = ok and Asserts.eq(inv.get_item("ore"), 2)
	inv.add_item("ore", 3)
	ok = ok and Asserts.eq(inv.get_item("ore"), 5)
	inv.add_item("ore", -10)
	ok = ok and Asserts.eq(inv.get_item("ore"), 0)
	var d := inv.to_dict()
	ok = ok and Asserts.ok(typeof(d) == TYPE_DICTIONARY)
	ok = ok and Asserts.eq(int(d.get("ore", 0)), 0)
	return ok

