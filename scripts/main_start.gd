extends Node2D

@onready var player_name_input = $CanvasLayer/StartScreen/HBoxContainer/VBoxContainer/PlayerName
@onready var start_screen = $CanvasLayer/StartScreen

func _ready():
	var host_button = $CanvasLayer/StartScreen/HBoxContainer/VBoxContainer/Host
	var join_button = $CanvasLayer/StartScreen/HBoxContainer/VBoxContainer/Join
	
	host_button.button_up.connect(_handle_host_click)
	join_button.button_up.connect(_handle_join_click)

func _handle_host_click():
	if _name_is_valid():
		MPlay.player_name = player_name_input.text
		if MPlay.host_game(3074) == OK:
			get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _handle_join_click():
	if _name_is_valid():
		MPlay.player_name = player_name_input.text
		if MPlay.join_game("127.0.0.1", 3074) == OK:
			get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _name_is_valid():
	return len(player_name_input.text) > 3

