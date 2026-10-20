class_name DropSpawner
extends Node
## Escuta o EventBus e solta uma gema de XP onde cada inimigo morre.
## Não conhece inimigos nem armas: só reage ao sinal.

@export var gem_scene: PackedScene
## Gemas criadas já no começo, guardadas na reserva.
@export var pool_initial_size: int = 100

var _pool: ObjectPool


func _ready() -> void:
	if gem_scene == null:
		push_warning("DropSpawner sem gem_scene.")
		return
	_pool = ObjectPool.new()
	_pool.name = "GemPool"
	_pool.scene = gem_scene
	_pool.initial_size = pool_initial_size
	_pool.warm_up = true
	add_child(_pool)
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(position: Vector3, xp_value: float) -> void:
	if xp_value <= 0.0:
		return
	var gem := _pool.acquire() as XpGem
	# Na altura do chão onde o inimigo estava (pode ser um morro).
	gem.drop(Vector3(position.x, HeightTerrain.ground_height(position.x, position.z), position.z), xp_value)
