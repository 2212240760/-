extends RefCounted

class_name AISimple

func pick_skill(controller, combatant) -> String:
	if controller == null:
		return ""
	if combatant == null:
		return ""
	for skill_id in controller.skill_defs.keys():
		if controller.can_cast(combatant, str(skill_id)):
			return str(skill_id)
	return ""

func act(controller, attacker, defender) -> bool:
	var skill_id := pick_skill(controller, attacker)
	if skill_id == "":
		return false
	controller.cast(attacker, defender, skill_id)
	return true
