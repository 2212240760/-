extends RefCounted

class_name ProductionJob

var recipe_id := ""
var qty := 1
var ticks_left := 0
var outputs: Array = []

func _init(_recipe_id := "", _qty := 1, _ticks_total := 0, _outputs: Array = []):
	recipe_id = _recipe_id
	qty = int(_qty)
	ticks_left = int(_ticks_total)
	outputs = _outputs

func tick(steps := 1) -> bool:
	ticks_left -= int(steps)
	return ticks_left <= 0
