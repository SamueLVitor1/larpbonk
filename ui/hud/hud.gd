class_name Hud
extends CanvasLayer
## Interface durante a partida. Só escuta o EventBus: não conhece o player.

@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	EventBus.player_xp_changed.connect(_on_player_xp_changed)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.run_time_changed.connect(_on_run_time_changed)


func _on_player_xp_changed(current: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	level_label.text = "Nv %d" % level


func _on_player_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current
	health_label.text = "%d / %d" % [ceili(current), ceili(max_value)]


func _on_run_time_changed(seconds: int) -> void:
	time_label.text = "%02d:%02d" % [floori(seconds / 60.0), seconds % 60]
