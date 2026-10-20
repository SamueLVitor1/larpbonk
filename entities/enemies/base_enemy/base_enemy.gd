class_name BaseEnemy
extends Node3D
## Molde de todo inimigo. Não usa física (Node3D, não CharacterBody3D): com
## centenas na tela, mover por código é bem mais barato.
## Os números vêm de um EnemyStats (.tres em data/enemies/).

@export var stats: EnemyStats
## Para de andar quando está mais perto que isso (evita tremer em cima do player).
@export var stop_distance: float = 0.5

var target: Node3D
var _move_speed: float = 3.0

@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_apply_stats()
	health.died.connect(_on_died)


## Anda reto até o player, só no plano XZ, e vira o corpo para ele.
## O modelo olha para +Z, por isso atan2(x, z).
func _physics_process(delta: float) -> void:
	if target == null:
		# Busca "preguiçosa": não depende da ordem em que player e inimigo entram na cena.
		target = get_tree().get_first_node_in_group("player") as Node3D
		if target == null:
			return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= stop_distance:
		return
	var direction := to_target.normalized()
	global_position += direction * _move_speed * delta
	rotation.y = atan2(direction.x, direction.z)


## Passa os números do .tres para os componentes. Os filhos rodam _ready()
## antes do pai, por isso o reset() aqui: a vida já tinha sido iniciada com o padrão.
func _apply_stats() -> void:
	if stats == null:
		push_warning("%s sem EnemyStats, usando valores padrão." % name)
		return
	health.max_health = stats.max_health
	health.reset()
	hitbox.damage = stats.contact_damage
	_move_speed = stats.move_speed


func _on_died() -> void:
	# Por enquanto só some; no passo 4 (pooling) volta para a reserva.
	queue_free()
