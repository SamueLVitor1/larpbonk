class_name Hud
extends CanvasLayer
## Interface durante a partida. Só escuta o EventBus: não conhece o player.

@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel


func _ready() -> void:
	EventBus.player_xp_changed.connect(_on_player_xp_changed)


func _on_player_xp_changed(current: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	level_label.text = "Nv %d" % level
