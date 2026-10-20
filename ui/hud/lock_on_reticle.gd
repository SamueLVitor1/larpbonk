class_name LockOnReticle
extends Control
## Mira da trava (tecla R): quatro cantinhos pulsando em volta do alvo, desenhados
## por código (sem textura). Segue o alvo projetando a posição 3D na tela.

@export var color := Color(1.0, 0.25, 0.2)
@export var outline_color := Color(0, 0, 0, 0.8)
## Meia largura do quadrado da mira (pixels).
@export var half_size: float = 56.0
## Comprimento de cada perninha do canto (pixels).
@export var corner_length: float = 24.0
@export var thickness: float = 6.0
## Quanto a mira "respira" (fração do tamanho) e quantas vezes por segundo.
@export var pulse_amount: float = 0.12
@export var pulse_speed: float = 3.0

var _target: Node3D
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	EventBus.lock_on_changed.connect(_on_lock_on_changed)


func _on_lock_on_changed(target: Node3D) -> void:
	_target = target
	_time = 0.0
	visible = target != null


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var height := (_target as BaseEnemy).aim_height if _target is BaseEnemy else 0.5
	var world_point := _target.global_position + Vector3.UP * height
	# Atrás da câmera a projeção "espelha" na tela: não desenha.
	if camera.is_position_behind(world_point):
		return
	var center := camera.unproject_position(world_point)
	var size := half_size * (1.0 + sin(_time * TAU * pulse_speed / 2.0) * pulse_amount)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var tip: Vector2 = center + corner * size
		var arm_x := Vector2(-corner.x * corner_length, 0)
		var arm_y := Vector2(0, -corner.y * corner_length)
		# Contorno escuro por baixo, para aparecer em qualquer fundo.
		for pass_color in [outline_color, color]:
			var w := thickness + (3.0 if pass_color == outline_color else 0.0)
			draw_line(tip, tip + arm_x, pass_color, w)
			draw_line(tip, tip + arm_y, pass_color, w)
