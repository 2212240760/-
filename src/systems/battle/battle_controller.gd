extends RefCounted

class_name BattleController

const Combatant = preload("res://src/systems/battle/battle_types.gd")

var skill_defs := {}

func tick(combatant: Combatant, delta: float) -> void:
	for k in combatant.cooldowns.keys():
		combatant.cooldowns[k] = maxf(0.0, float(combatant.cooldowns[k]) - delta)

func can_cast(combatant: Combatant, skill_id: String) -> bool:
	return float(combatant.cooldowns.get(skill_id, 0.0)) <= 0.0

func cast(attacker: Combatant, defender: Combatant, skill_id: String) -> void:
	var s: Dictionary = skill_defs[skill_id]
	attacker.cooldowns[skill_id] = float(s["cooldown"])
	defender.hp = max(0, defender.hp - int(s["power"]))
