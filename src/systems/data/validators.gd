extends RefCounted

const DataError = preload("res://src/systems/data/data_errors.gd")

static func require_keys(obj: Dictionary, keys: Array[String], path: String) -> Array:
	var errors: Array = []
	for k in keys:
		if not obj.has(k):
			errors.append(DataError.new(path, "missing_key", "missing key: %s" % k))
	return errors

static func require_type(obj: Dictionary, key: String, t: int, path: String) -> Array:
	var errors: Array = []
	if obj.has(key) and typeof(obj[key]) != t:
		errors.append(DataError.new(path, "type_mismatch", "key %s expected %s" % [key, str(t)]))
	return errors
