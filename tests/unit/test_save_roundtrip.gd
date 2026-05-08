extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const SaveGame = preload("res://src/systems/save/save_game.gd")

func run() -> bool:
	var s := SaveGame.new()
	s.progress["chapter_id"] = "chapter_02"
	var text := JSON.stringify(s.to_dict())
	var back = JSON.parse_string(text)
	var ok := true
	ok = ok and Asserts.eq(back["progress"]["chapter_id"], "chapter_02")
	ok = ok and Asserts.eq(int(back["version"]), 1)
	return ok
