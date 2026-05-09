extends RefCounted

const Asserts = preload("res://tests/runner/asserts.gd")
const BattleCapture = preload("res://src/systems/battle/battle_capture.gd")
const CaptureContext = preload("res://src/systems/capture/capture_types.gd")

func run() -> bool:
	var bc := BattleCapture.new()
	var ctx := CaptureContext.new()
	ctx.hp_ratio = 0.2
	ctx.in_window = true
	ctx.resist_stacks = 0
	ctx.rarity = "common"
	var power := 0.35
	var ok := true
	ok = ok and Asserts.ok(bc.attempt_with_roll(power, ctx, 0.0))
	ok = ok and Asserts.ok(not bc.attempt_with_roll(power, ctx, 0.99))
	return ok

