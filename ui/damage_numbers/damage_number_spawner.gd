class_name DamageNumberSpawner
extends Node
## Escuta o EventBus e mostra um número de dano onde cada inimigo é atingido.

@export var number_scene: PackedScene
@export var pool_initial_size: int = 40

var _pool: ObjectPool


func _ready() -> void:
	if number_scene == null:
		push_warning("DamageNumberSpawner sem number_scene.")
		return
	_pool = ObjectPool.new()
	_pool.name = "DamageNumberPool"
	_pool.scene = number_scene
	_pool.initial_size = pool_initial_size
	_pool.warm_up = true
	add_child(_pool)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)


func _on_enemy_damaged(position: Vector3, amount: float) -> void:
	var number := _pool.acquire() as DamageNumber
	number.show_damage(position, amount)
