extends RefCounted

class_name BattleCapture

const CaptureSystem = preload("res://src/systems/capture/capture_system.gd")
const CaptureContext = preload("res://src/systems/capture/capture_types.gd")

var capture_system := CaptureSystem.new()
var rng := RandomNumberGenerator.new()

func attempt(ball_power: float, ctx: CaptureContext) -> bool:
	var p := capture_system.chance(ball_power, ctx)
	return rng.randf() < p

func attempt_with_roll(ball_power: float, ctx: CaptureContext, roll: float) -> bool:
	var p := capture_system.chance(ball_power, ctx)
	return float(roll) < p
