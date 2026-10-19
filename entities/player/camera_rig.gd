class_name CameraRig
extends Node3D
## Câmera em 3ª pessoa: o rig gira no eixo Y (yaw) e o SpringArm no eixo X (pitch).
## O SpringArm encurta sozinho quando há algo entre o player e a câmera.

@export var mouse_sensitivity: float = 0.003
@export_range(-89.0, 0.0) var min_pitch_deg: float = -60.0
@export_range(0.0, 89.0) var max_pitch_deg: float = 20.0

@onready var spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Impede o SpringArm de "bater" na própria cápsula do player.
	var body := get_parent() as CollisionObject3D
	if body:
		spring_arm.add_excluded_object(body.get_rid())


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
