class_name LoadingScreen
extends CanvasLayer
## Tela preta "CARREGANDO..." estilo NES, usada pelo SceneLoader.
## Os pontinhos entram um a um; o fade é curto para não atrasar o jogo.

@export var fade_time: float = 0.25
@export var dot_interval: float = 0.25

@onready var veil: Control = $Veil
@onready var label: Label = %LoadingLabel

var _dots := 0
var _dot_timer := 0.0


func _ready() -> void:
	veil.modulate.a = 0.0
	veil.hide()


func _process(delta: float) -> void:
	if not veil.visible:
		return
	_dot_timer += delta
	if _dot_timer >= dot_interval:
		_dot_timer = 0.0
		_dots = (_dots + 1) % 4
		label.text = "CARREGANDO" + ".".repeat(_dots)


## Escurece a tela (rápido) e espera terminar.
func cover() -> void:
	_dots = 0
	label.text = "CARREGANDO"
	veil.show()
	await _fade_to(1.0)


## Clareia e esconde a tela.
func uncover() -> void:
	await _fade_to(0.0)
	veil.hide()


func _fade_to(alpha: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil, "modulate:a", alpha, fade_time)
	await tween.finished
