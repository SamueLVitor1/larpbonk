class_name EnemySpawner
extends Node3D
## Cria inimigos a cada intervalo, num ponto aleatório de um círculo em volta do player.
## Os inimigos vêm de um ObjectPool próprio (filho do spawner), não de instantiate().

@export var enemy_scene: PackedScene
## Números de balanceamento (data/spawner/*.tres).
@export var config: SpawnerConfig
## Quantos ângulos sortear procurando um ponto fora da câmera.
@export var offscreen_attempts: int = 10
## Inimigos criados já no começo, guardados na reserva.
@export var pool_initial_size: int = 50

var elapsed_time: float = 0.0
var _time_until_spawn: float = 0.0
var _pool: ObjectPool


## O pool é criado por código para o spawner funcionar só com o enemy_scene,
## sem precisar montar nada a mais na cena.
func _ready() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner sem enemy_scene.")
		return
	_pool = ObjectPool.new()
	_pool.name = "EnemyPool"
	_pool.scene = enemy_scene
	_pool.initial_size = pool_initial_size
	add_child(_pool)


func _physics_process(delta: float) -> void:
	if config == null:
		return
	elapsed_time += delta
	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return
	_time_until_spawn = current_interval()
	_spawn_enemy()


## Intervalo atual: começa em start_interval e cai até end_interval.
## ease(..., 0.5) faz cair mais rápido no começo e suavizar no fim,
## assim o primeiro minuto já esquenta sem virar caos logo de cara.
func current_interval() -> float:
	var progress := clampf(elapsed_time / config.ramp_duration, 0.0, 1.0)
	return lerpf(config.start_interval, config.end_interval, ease(progress, 0.5))


func _spawn_enemy() -> void:
	if _pool == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= config.max_enemies:
		return
	var spawn_position: Variant = _find_offscreen_position(player.global_position)
	if spawn_position == null:
		# Tudo à vista (raro): pula esta vez em vez de brotar na cara do player.
		return
	var enemy := _pool.acquire() as Node3D
	enemy.global_position = spawn_position


## Sorteia pontos no círculo em volta do player até achar um que a câmera não vê.
## Com câmera em 3ª pessoa, na prática eles nascem atrás e dos lados.
func _find_offscreen_position(center: Vector3) -> Variant:
	var camera := get_viewport().get_camera_3d()
	for i in offscreen_attempts:
		var angle := randf() * TAU
		var point := Vector3(center.x + cos(angle) * config.spawn_radius, 0.0, center.z + sin(angle) * config.spawn_radius)
		# Testa o meio do corpo, não o pé, para não aparecer metade do porco.
		if camera == null or not camera.is_position_in_frustum(point + Vector3.UP * 0.5):
			return point
	return null
