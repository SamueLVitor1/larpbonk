class_name HitboxComponent
extends Area3D
## Área que causa dano em toda Hurtbox que estiver encostando.
## Quem ela acerta é definido pelo collision_mask (ver layers no project.godot).
## Checa a cada tick para o dano de contato ser contínuo; a invulnerabilidade
## do HealthComponent evita dano a cada frame.

signal hit(hurtbox: HurtboxComponent)

@export var damage: float = 10.0


func _ready() -> void:
	monitorable = false
	collision_layer = 0


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			area.receive_hit(damage)
			hit.emit(area)
