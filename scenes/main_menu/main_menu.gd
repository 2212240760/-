extends Control

@onready var status_label: Label = $Margin/VBox/Status
@onready var new_btn: Button = $Margin/VBox/NewGame
@onready var load_btn: Button = $Margin/VBox/LoadGame
@onready var quit_btn: Button = $Margin/VBox/Quit

func _ready() -> void:
	new_btn.pressed.connect(_on_new)
	load_btn.pressed.connect(_on_load)
	quit_btn.pressed.connect(_on_quit)

func _on_new() -> void:
	Game.new_game()
	Game.goto_overworld()

func _on_load() -> void:
	if Game.load_game():
		Game.goto_overworld()
	else:
		status_label.text = "读取失败"

func _on_quit() -> void:
	get_tree().quit()

