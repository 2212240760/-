extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")

func run() -> bool:
	var ok := true
	ok = ok and Asserts.eq(1, 1)
	ok = ok and Asserts.ok(true)
	return ok
