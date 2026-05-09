extends RefCounted

class_name SaveIO

const SaveGameScript = preload("res://src/systems/save/save_game.gd")

func write(save, slot := "slot1") -> bool:
	var path = "user://%s.save.json" % slot
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(save.to_dict()))
	return true

func read(slot := "slot1") -> Dictionary:
	var path = "user://%s.save.json" % slot
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"_error": "open_failed"}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_error": "parse_failed"}
	return parsed
