extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const Codex = preload("res://src/systems/progress/codex.gd")

func run() -> bool:
	var c := Codex.new()
	c.mark_captured("slime_001")
	var ok := true
	ok = ok and Asserts.ok(c.discovered.has("slime_001"))
	ok = ok and Asserts.eq(c.captured_count("slime_001"), 1)
	return ok
