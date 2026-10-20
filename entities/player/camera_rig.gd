class_name CameraRig
extends Node3D
## Câmera em 3ª pessoa: o rig gira no eixo Y (yaw) e o SpringArm no eixo X (pitch).
## O SpringArm encurta sozinho quando há algo entre o player e a câmera.

@export var mouse_sensitivity: float = 0.003
@export_range(-89.0, 0.0) var min_pitch_deg: float = -60.0
@export_range(0.0, 89.0) var max_pitch_deg: float = 20.0

@export_group("Shake")
## Tremer a câmera quando o player toma dano (futuro: opção no menu).
@export var shake_enabled: bool = true
@export var shake_duration: float = 0.15
## Deslocamento máximo da câmera durante o tremor (metros).
@export var shake_strength: float = 0.12

var _shake_time_left: float = 0.0
var _last_health: float = -1.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Impede o SpringArm de "bater" na própria cápsula do player.
	var body := get_parent() as CollisionObject3D
	if body:
		spring_arm.add_excluded_object(body.get_rid())
	EventBus.player_health_changed.connect(_on_player_health_changed)


## Treme só quando a vida diminui (cura e aumento de vida máxima não contam).
func _on_player_health_changed(current: float, _max_value: float) -> void:
	if _last_health >= 0.0 and current < _last_health and shake_enabled:
		_shake_time_left = shake_duration
	_last_health = current


## h_offset/v_offset deslocam a imagem sem mexer no SpringArm nem na mira.
func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		return
	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	# Diminui até zero ao longo do tremor: começa forte e acalma.
	var strength := shake_strength * (_shake_time_left / shake_duration)
	camera.h_offset = randf_range(-strength, strength)
	camera.v_offset = randf_range(-strength, strength)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
