class_name DeathPuffSpawner
extends Node
## Escuta o EventBus e solta um "puf" onde cada inimigo morre.

@export var puff_scene: PackedScene
@export var pool_initial_size: int = 20
## Altura do "puf" em relação ao pé do inimigo (meio do corpo).
@export var height: float = 0.45

var _pool: ObjectPool


func _ready() -> void:
	if puff_scene == null:
		push_warning("DeathPuffSpawner sem puff_scene.")
		return
	_pool = ObjectPool.new()
	_pool.name = "DeathPuffPool"
	_pool.scene = puff_scene
	_pool.initial_size = pool_initial_size
	add_child(_pool)
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(position: Vector3, _xp_value: float) -> void:
	var puff := _pool.acquire() as DeathPuff
	puff.play_at(position + Vector3.UP * height)
