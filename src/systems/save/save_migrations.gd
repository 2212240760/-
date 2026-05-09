extends RefCounted

class_name SaveMigrations

static func normalize(raw: Dictionary) -> Dictionary:
	var d = raw.duplicate(true)
	if not d.has("version"):
		d["version"] = 1
	return d

static func upgrade(raw: Dictionary) -> Dictionary:
	var d = normalize(raw)
	return d
