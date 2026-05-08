extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const BattleController = preload("res://src/systems/battle/battle_controller.gd")
const Combatant = preload("res://src/systems/battle/battle_types.gd")

func run() -> bool:
	var bc := BattleController.new()
	bc.skill_defs = {"bubble": {"cooldown": 2.0, "power": 1}}

	var a := Combatant.new()
	var d := Combatant.new()
	a.cooldowns = {}
	d.hp = 10

	bc.cast(a, d, "bubble")
	var ok := true
	ok = ok and Asserts.ok(not bc.can_cast(a, "bubble"))
	bc.tick(a, 2.0)
	ok = ok and Asserts.ok(bc.can_cast(a, "bubble"))
	return ok
