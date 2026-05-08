extends RefCounted

class_name DataRegistry

var _cache: Dictionary = {}

func load_json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_cache[path] = {"_error": "open_failed", "_path": path}
		return _cache[path]

	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		_cache[path] = {"_error": "parse_failed", "_path": path}
		return _cache[path]

	var t := typeof(parsed)
	if t != TYPE_DICTIONARY and t != TYPE_ARRAY:
		_cache[path] = {"_error": "invalid_type", "_path": path, "_type": t}
		return _cache[path]

	_cache[path] = parsed
	return parsed
