extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const GameScript = preload("res://src/app/game.gd")

func run() -> bool:
	var g = GameScript.new()
	g.new_game()
	var ok := true
	ok = ok and Asserts.eq(g.inventory.get_item("ball_basic"), 3)
	ok = ok and Asserts.ok(g.base.unlocked_recipes.has("smelt_ingot"))
	g.inventory.add_item("ball_basic", -1)
	g.codex.mark_captured("slime_001")
	ok = ok and Asserts.eq(g.inventory.get_item("ball_basic"), 2)
	ok = ok and Asserts.eq(g.codex.captured_count("slime_001"), 1)
	g.base.unlocked_recipes["craft_sword"] = true
	g.save.inventory = g.inventory.to_dict()
	g.save.codex = {"discovered": g.codex.discovered.duplicate(true), "captured": g.codex.captured.duplicate(true)}
	g.save.base_state = {
		"inventory": g.base.inventory.duplicate(true),
		"jobs": [],
		"buildings": {},
		"unlocked_recipes": g.base.unlocked_recipes.duplicate(true)
	}
	var text := JSON.stringify(g.save.to_dict())
	var back = JSON.parse_string(text)
	ok = ok and Asserts.eq(int(back.get("version", 0)), 1)
	ok = ok and Asserts.eq(int(back.get("inventory", {}).get("ball_basic", 0)), 2)
	ok = ok and Asserts.eq(int(back.get("codex", {}).get("captured", {}).get("slime_001", 0)), 1)
	ok = ok and Asserts.ok(Dictionary(back.get("base_state", {})).get("unlocked_recipes", {}).has("craft_sword"))
	return ok
