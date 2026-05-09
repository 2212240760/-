extends Control

@onready var info_label: Label = $Margin/VBox/Info
@onready var status_label: Label = $Margin/VBox/Status
@onready var battle_btn: Button = $Margin/VBox/GoBattle
@onready var base_btn: Button = $Margin/VBox/GoBase
@onready var save_btn: Button = $Margin/VBox/Save
@onready var menu_btn: Button = $Margin/VBox/Menu

func _ready() -> void:
	battle_btn.pressed.connect(_on_battle)
	base_btn.pressed.connect(_on_base)
	save_btn.pressed.connect(_on_save)
	menu_btn.pressed.connect(_on_menu)
	_refresh()

func _refresh() -> void:
	var balls := Game.inventory.get_item("ball_basic")
	var ore := Game.base.get_item("ore")
	var ingot := Game.base.get_item("ingot")
	var captured := 0
	for k in Game.codex.captured.keys():
		captured += int(Game.codex.captured[k])
	info_label.text = "区域: %s\n捕捉球: %d\n矿石: %d  锭: %d\n已捕获总数: %d" % [Game.current_region_id, balls, ore, ingot, captured]

func _on_battle() -> void:
	Game.goto_battle()

func _on_base() -> void:
	Game.goto_base()

func _on_save() -> void:
	status_label.text = "已保存" if Game.save_game() else "保存失败"
	_refresh()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

