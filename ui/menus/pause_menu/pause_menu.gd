class_name PauseMenu
extends CanvasLayer
## Pausa no Esc. Só abre se o jogo não estiver pausado por outra tela
## (cartas de level up, game over), para não despausar no meio delas.
## process_mode = Always para funcionar pausada.

@export_file("*.tscn") var main_menu_scene: String = "res://ui/menus/main_menu/main_menu.tscn"

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	hide()
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_resume()
	elif not get_tree().paused:
		_open()
	else:
		return  # outra tela está com a pausa: deixa ela cuidar
	get_viewport().set_input_as_handled()


func _open() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus.call_deferred()


func _resume() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)
