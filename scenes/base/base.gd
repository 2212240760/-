extends Control

@onready var info_label: Label = $Margin/VBox/Info
@onready var status_label: Label = $Margin/VBox/Status
@onready var start_btn: Button = $Margin/VBox/StartSmelt
@onready var upgrade_btn: Button = $Margin/VBox/UpgradeForge
@onready var helper_btn: Button = $Margin/VBox/AssignHelper
@onready var research_btn: Button = $Margin/VBox/ResearchSword
@onready var sword_btn: Button = $Margin/VBox/StartSword
@onready var tick1_btn: Button = $Margin/VBox/Tick1
@onready var tick3_btn: Button = $Margin/VBox/Tick3
@onready var back_btn: Button = $Margin/VBox/Back

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	upgrade_btn.pressed.connect(_on_upgrade)
	helper_btn.pressed.connect(_on_helper)
	research_btn.pressed.connect(_on_research)
	sword_btn.pressed.connect(_on_sword)
	tick1_btn.pressed.connect(_on_tick1)
	tick3_btn.pressed.connect(_on_tick3)
	back_btn.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	var ore = Game.base.get_item("ore")
	var ingot = Game.base.get_item("ingot")
	var forge = Game.base.buildings.get("forge", null)
	if forge == null:
		forge = Game.base.ensure_building("forge", "forge", 1, 0)
	var forge_level = int(forge.level)
	var forge_helpers = int(forge.assigned_helpers.size())
	var unlocked_sword = Game.base.unlocked_recipes.has("craft_sword")
	var jobs_text = ""
	for j in Game.base.jobs:
		jobs_text += "%s x%d (%d)\n" % [str(j.recipe_id), int(j.qty), int(j.ticks_left)]
	info_label.text = "熔炉 Lv.%d 助手:%d\n矿石: %d  锭: %d\n已解锁短剑:%s\n队列:\n%s" % [forge_level, forge_helpers, ore, ingot, "是" if unlocked_sword else "否", jobs_text]
	sword_btn.disabled = not unlocked_sword

func _on_start() -> void:
	var ok = Game.base.start_job("smelt_ingot", 1, "forge")
	status_label.text = "已开工" if ok else "无法开工"
	_refresh()

func _on_upgrade() -> void:
	var forge = Game.base.buildings.get("forge", null)
	if forge == null:
		forge = Game.base.ensure_building("forge", "forge", 1, 0)
	if Game.base.get_item("ore") < 2:
		status_label.text = "矿石不足"
		_refresh()
		return
	Game.base.add_item("ore", -2)
	var next_level = int(forge.level) + 1
	var helpers = int(forge.assigned_helpers.size())
	Game.base.ensure_building("forge", "forge", next_level, helpers)
	status_label.text = "熔炉升级"
	_refresh()

func _on_helper() -> void:
	var forge = Game.base.buildings.get("forge", null)
	if forge == null:
		forge = Game.base.ensure_building("forge", "forge", 1, 0)
	var helpers = int(forge.assigned_helpers.size())
	if helpers >= 5:
		status_label.text = "助手已满"
		_refresh()
		return
	Game.base.ensure_building("forge", "forge", int(forge.level), helpers + 1)
	status_label.text = "已分配助手"
	_refresh()

func _on_research() -> void:
	if Game.base.unlocked_recipes.has("craft_sword"):
		status_label.text = "已解锁"
		_refresh()
		return
	if Game.base.get_item("ore") < 3:
		status_label.text = "矿石不足"
		_refresh()
		return
	Game.base.add_item("ore", -3)
	Game.base.unlocked_recipes["craft_sword"] = true
	status_label.text = "研究完成"
	_refresh()

func _on_sword() -> void:
	var ok = Game.base.start_job("craft_sword", 1, "forge")
	status_label.text = "已开工" if ok else "无法开工"
	_refresh()

func _on_tick1() -> void:
	var completed = Game.base.tick(1)
	status_label.text = "tick完成: %d" % completed
	_refresh()

func _on_tick3() -> void:
	var completed = Game.base.tick(3)
	status_label.text = "tick完成: %d" % completed
	_refresh()

func _on_back() -> void:
	Game.goto_overworld()
