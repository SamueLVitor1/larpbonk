class_name Player
extends CharacterBody3D
## Movimento do player relativo à câmera. O corpo nunca gira:
## só o Model vira para a direção do movimento, assim a câmera não "gira junto".

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var turn_speed: float = 12.0
## Ajuste se o modelo andar de costas ou de lado (ex.: 180).
@export var model_yaw_offset_deg: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model: Node3D = $Model
@onready var camera_rig: CameraRig = $CameraRig
@onready var health: HealthComponent = $HealthComponent
@onready var anim: AnimationPlayer = model.find_child("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_rig.global_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		var target_yaw := atan2(direction.x, direction.z) + deg_to_rad(model_yaw_offset_deg)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	if anim == null:
		return
	if not is_on_floor():
		_play("jump")
	elif Vector2(velocity.x, velocity.z).length() > 0.1:
		_play("run-loop")
	else:
		_play("idle-loop")


## Toca a animação pelo nome, aceitando com ou sem o sufixo "-loop".
func _play(anim_name: String) -> void:
	if not anim.has_animation(anim_name):
		anim_name = anim_name.trim_suffix("-loop")
	if anim.current_animation != anim_name and anim.has_animation(anim_name):
		anim.play(anim_name, 0.15)


func _on_damaged(amount: float) -> void:
	print("Player tomou %.0f de dano (vida: %.0f/%.0f)" % [amount, health.current_health, health.max_health])


func _on_died() -> void:
	# Por enquanto só avisa; o game over de verdade vem no passo 7 (HUD).
	print("Player morreu!")
