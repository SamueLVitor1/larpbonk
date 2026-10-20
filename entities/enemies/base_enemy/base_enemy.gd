class_name BaseEnemy
extends Node3D
## Molde de todo inimigo. Não usa física (Node3D, não CharacterBody3D): com
## centenas na tela, mover por código é bem mais barato.
## Os números vêm de um EnemyStats (.tres em data/enemies/).

@export var stats: EnemyStats

@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_apply_stats()
	health.died.connect(_on_died)


## Passa os números do .tres para os componentes. Os filhos rodam _ready()
## antes do pai, por isso o reset() aqui: a vida já tinha sido iniciada com o padrão.
func _apply_stats() -> void:
	if stats == null:
		push_warning("%s sem EnemyStats, usando valores padrão." % name)
		return
	health.max_health = stats.max_health
	health.reset()
	hitbox.damage = stats.contact_damage


func _on_died() -> void:
	# Por enquanto só some; no passo 4 (pooling) volta para a reserva.
	queue_free()
