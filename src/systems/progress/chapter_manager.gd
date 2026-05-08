extends RefCounted

class_name ChapterManager

func can_unlock(chapter: Dictionary, state: Dictionary) -> bool:
	var req = chapter.get("requires", {})
	if typeof(req) != TYPE_DICTIONARY:
		req = {}

	if req.has("boss_defeated") and state.get("boss_defeated", "") != req["boss_defeated"]:
		return false
	if req.has("base_level") and int(state.get("base_level", 1)) < int(req["base_level"]):
		return false
	if req.has("codex_captured_total") and int(state.get("codex_captured_total", 0)) < int(req["codex_captured_total"]):
		return false
	return true
