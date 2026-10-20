class_name HurtboxComponent
extends Area3D
## A "pele" de quem pode tomar dano. Repassa o dano para o HealthComponent.
## Só existe para ser encontrada: não detecta nada sozinha.

@export var health: HealthComponent


func _ready() -> void:
	monitoring = false
	collision_mask = 0


func receive_hit(damage: float) -> void:
	if health:
		health.take_damage(damage)
