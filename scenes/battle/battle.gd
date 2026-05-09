extends Control

const CaptureContext = preload("res://src/systems/capture/capture_types.gd")
const BattleCapture = preload("res://src/systems/battle/battle_capture.gd")

@onready var info_label: Label = $Margin/VBox/Info
@onready var status_label: Label = $Margin/VBox/Status
@onready var attack_btn: Button = $Margin/VBox/Attack
@onready var capture_btn: Button = $Margin/VBox/Capture
@onready var leave_btn: Button = $Margin/VBox/Leave

var species_id := "slime_001"
var rarity := "common"
var max_hp := 30
var hp := 30
var resist_stacks := 0
var ended := false

var battle_capture := BattleCapture.new()

func _ready() -> void:
	attack_btn.pressed.connect(_on_attack)
	capture_btn.pressed.connect(_on_capture)
	leave_btn.pressed.connect(_on_leave)
	if Game.current_encounter_species_id != "":
		species_id = Game.current_encounter_species_id
	_init_enemy()
	_refresh()

func _init_enemy() -> void:
	if Game.species_defs.has(species_id):
		var sp = Game.species_defs[species_id]
		rarity = str(sp.rarity)
		var base_stats: Dictionary = sp.base_stats
		max_hp = int(base_stats.get("hp", 30))
		hp = max_hp

func _refresh() -> void:
	var balls = Game.inventory.get_item("ball_basic")
	info_label.text = "野生: %s (%s)\nHP: %d/%d\n捕捉球: %d" % [species_id, rarity, hp, max_hp, balls]
	capture_btn.disabled = ended
	attack_btn.disabled = ended
	leave_btn.text = "返回大地图" if ended else "逃跑"

func _on_attack() -> void:
	if ended:
		return
	hp = max(0, hp - 6)
	status_label.text = "造成伤害"
	if hp == 0:
		_settle(true, false)
	_refresh()

func _on_capture() -> void:
	if ended:
		return
	if Game.inventory.get_item("ball_basic") <= 0:
		status_label.text = "没有捕捉球"
		_refresh()
		return
	Game.inventory.add_item("ball_basic", -1)

	var ctx = CaptureContext.new()
	ctx.hp_ratio = float(hp) / float(max_hp)
	ctx.in_window = hp <= int(max_hp * 0.25)
	ctx.resist_stacks = resist_stacks
	ctx.rarity = rarity

	var power = Game.item_defs.get_power("ball_basic")
	var ok = battle_capture.attempt_with_roll(power, ctx, Game.rng.randf())
	if ok:
		Game.codex.mark_captured(species_id)
		status_label.text = "捕获成功"
		_settle(true, true)
	else:
		resist_stacks += 1
		status_label.text = "捕获失败"
	_refresh()

func _settle(victory: bool, captured: bool) -> void:
	ended = true
	if not victory:
		return
	var dt = Game.load_region_drop_table("sample_region_01")
	var drop = dt.roll(Game.rng)
	if drop.is_empty():
		return
	var id = str(drop.get("id", ""))
	var qty = int(drop.get("qty", 0))
	if qty <= 0 or id == "":
		return
	if id.begins_with("ball_"):
		Game.inventory.add_item(id, qty)
	else:
		Game.base.add_item(id, qty)
	status_label.text = "%s\n掉落: %s x%d" % [status_label.text, id, qty]

func _on_leave() -> void:
	Game.goto_overworld()
