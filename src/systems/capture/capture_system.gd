extends RefCounted

class_name CaptureSystem

const CaptureContext = preload("res://src/systems/capture/capture_types.gd")

func chance(ball_power: float, ctx: CaptureContext) -> float:
	var hp_bonus := lerpf(0.6, 1.2, clampf(1.0 - ctx.hp_ratio, 0.0, 1.0))
	var window_bonus := 1.5 if ctx.in_window else 1.0
	var rarity_mul := 1.0
	if ctx.rarity == "rare":
		rarity_mul = 0.7
	elif ctx.rarity == "epic":
		rarity_mul = 0.5
	elif ctx.rarity == "legend":
		rarity_mul = 0.3
	var resist_mul := pow(0.85, float(ctx.resist_stacks))
	return clampf(ball_power * hp_bonus * window_bonus * rarity_mul * resist_mul, 0.01, 0.95)
