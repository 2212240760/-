extends Control

@onready var info_label: Label = $Margin/VBox/Info
@onready var status_label: Label = $Margin/VBox/Status
@onready var start_btn: Button = $Margin/VBox/StartSmelt
@onready var tick1_btn: Button = $Margin/VBox/Tick1
@onready var tick3_btn: Button = $Margin/VBox/Tick3
@onready var back_btn: Button = $Margin/VBox/Back

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	tick1_btn.pressed.connect(_on_tick1)
	tick3_btn.pressed.connect(_on_tick3)
	back_btn.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	var ore := Game.base.get_item("ore")
	var ingot := Game.base.get_item("ingot")
	var jobs_text := ""
	for j in Game.base.jobs:
		jobs_text += "%s x%d (%d)\n" % [str(j.recipe_id), int(j.qty), int(j.ticks_left)]
	info_label.text = "矿石: %d  锭: %d\n队列:\n%s" % [ore, ingot, jobs_text]

func _on_start() -> void:
	var ok := Game.base.start_job("smelt_ingot", 1)
	status_label.text = "已开工" if ok else "无法开工"
	_refresh()

func _on_tick1() -> void:
	var completed := Game.base.tick(1)
	status_label.text = "tick完成: %d" % completed
	_refresh()

func _on_tick3() -> void:
	var completed := Game.base.tick(3)
	status_label.text = "tick完成: %d" % completed
	_refresh()

func _on_back() -> void:
	Game.goto_overworld()

