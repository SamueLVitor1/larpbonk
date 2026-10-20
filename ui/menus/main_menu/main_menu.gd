class_name MainMenu
extends Control
## Tela de título (estilo NES): Jogar abre a seleção de personagem, Sair fecha o jogo.
## Setas/Enter navegam pelo foco do Godot; passar o mouse num item dá foco nele,
## então teclado e mouse sempre mostram o mesmo item selecionado (cursor ►).

@export_file("*.tscn") var game_scene: String = "res://ui/menus/character_select/character_select.tscn"
## Duração de cada fase do pisca-pisca do cursor.
@export var blink_interval: float = 0.4
## Espaço, em pixels, entre o cursor e o texto do item.
@export var cursor_gap: float = 24.0

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var cursor: TextureRect = %Cursor

var _blink_timer: Timer


func _ready() -> void:
	# Vindo de uma partida, o jogo pode estar pausado e com o mouse preso.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	for button: Button in [play_button, quit_button]:
		button.focus_entered.connect(_move_cursor.bind(button))
		button.mouse_entered.connect(button.grab_focus)
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_blink_timer = Timer.new()
	_blink_timer.wait_time = blink_interval
	_blink_timer.timeout.connect(func() -> void: cursor.visible = not cursor.visible)
	add_child(_blink_timer)

	# O VBoxContainer só posiciona os botões no fim do frame; antes disso o
	# cursor iria para o lugar errado.
	await get_tree().process_frame
	play_button.grab_focus()


func _move_cursor(button: Button) -> void:
	cursor.global_position = Vector2(
		button.global_position.x - cursor.size.x - cursor_gap,
		button.global_position.y + (button.size.y - cursor.size.y) / 2.0
	)
	# Reinicia o pisca para o cursor aparecer na hora em que troca de item.
	cursor.visible = true
	_blink_timer.start()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()
