extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const ChapterManager = preload("res://src/systems/progress/chapter_manager.gd")

func run() -> bool:
	var cm := ChapterManager.new()
	var chapter := {
		"requires": {"boss_defeated": "boss_01", "base_level": 3, "codex_captured_total": 10}
	}
	var ok := true
	ok = ok and Asserts.ok(not cm.can_unlock(chapter, {"boss_defeated": "boss_01", "base_level": 2, "codex_captured_total": 10}))
	ok = ok and Asserts.ok(not cm.can_unlock(chapter, {"boss_defeated": "boss_02", "base_level": 3, "codex_captured_total": 10}))
	ok = ok and Asserts.ok(not cm.can_unlock(chapter, {"boss_defeated": "boss_01", "base_level": 3, "codex_captured_total": 9}))
	ok = ok and Asserts.ok(cm.can_unlock(chapter, {"boss_defeated": "boss_01", "base_level": 3, "codex_captured_total": 10}))
	return ok
