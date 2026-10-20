class_name MainMenu
extends Control
## Tela inicial: Jogar abre a seleção de personagem, Sair fecha o jogo.

@export_file("*.tscn") var game_scene: String = "res://ui/menus/character_select/character_select.tscn"

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# Vindo de uma partida, o jogo pode estar pausado e com o mouse preso.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus.call_deferred()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()
