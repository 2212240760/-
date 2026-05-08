extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const CaptureSystem = preload("res://src/systems/capture/capture_system.gd")
const CaptureContext = preload("res://src/systems/capture/capture_types.gd")

func run() -> bool:
	var cs := CaptureSystem.new()
	var ctx := CaptureContext.new()
	ctx.hp_ratio = 0.2
	ctx.in_window = false
	ctx.resist_stacks = 0
	var a := cs.chance(0.35, ctx)
	ctx.in_window = true
	var b := cs.chance(0.35, ctx)
	ctx.in_window = true
	ctx.resist_stacks = 3
	var c := cs.chance(0.35, ctx)
	var ok := true
	ok = ok and Asserts.ok(b > a)
	ok = ok and Asserts.ok(c < b)
	return ok
