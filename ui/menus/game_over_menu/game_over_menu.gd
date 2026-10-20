class_name GameOverMenu
extends CanvasLayer
## Tela de morte: pausa o jogo e mostra tempo sobrevivido e nível.
## Guarda esses valores ouvindo o EventBus durante a partida, sem conhecer
## player nem spawner. process_mode = Always para funcionar pausada.

@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel
@onready var restart_button: Button = %RestartButton

var _seconds: int = 0
var _level: int = 1


func _ready() -> void:
	hide()
	EventBus.run_time_changed.connect(_on_run_time_changed)
	EventBus.player_xp_changed.connect(_on_player_xp_changed)
	EventBus.player_died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart_pressed)


func _on_run_time_changed(seconds: int) -> void:
	_seconds = seconds


func _on_player_xp_changed(_current: float, _needed: float, level: int) -> void:
	_level = level


func _on_player_died() -> void:
	time_label.text = "Tempo sobrevivido: %02d:%02d" % [floori(_seconds / 60.0), _seconds % 60]
	level_label.text = "Nível: %d" % _level
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button.grab_focus.call_deferred()


## Recarregar a cena recomeça tudo do zero (vida, nível, relógio, pools)
## sem precisar resetar cada sistema na mão. O EventBus (autoload) sobrevive,
## mas as conexões dos nós antigos somem junto com eles.
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
