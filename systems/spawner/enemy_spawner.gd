class_name EnemySpawner
extends Node3D
## Cria inimigos a cada intervalo, num ponto aleatório de um círculo em volta do player.
## Por enquanto usa instantiate(); no passo 4 passa a pegar do pool.

@export var enemy_scene: PackedScene
## Intervalo entre inimigos no começo da partida (segundos).
@export var start_interval: float = 1.5
## Intervalo mínimo, alcançado ao fim da rampa.
@export var end_interval: float = 0.3
## Quanto tempo (segundos) leva para ir do start ao end.
@export var ramp_duration: float = 180.0
## Distância do player em que os inimigos nascem (metros).
@export var spawn_radius: float = 15.0
## Teto de inimigos vivos, para não travar enquanto não há pooling.
@export var max_enemies: int = 100
## Quantos ângulos sortear procurando um ponto fora da câmera.
@export var offscreen_attempts: int = 10

var elapsed_time: float = 0.0
var _time_until_spawn: float = 0.0


func _physics_process(delta: float) -> void:
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
	var progress := clampf(elapsed_time / ramp_duration, 0.0, 1.0)
	return lerpf(start_interval, end_interval, ease(progress, 0.5))


func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	var spawn_position: Variant = _find_offscreen_position(player.global_position)
	if spawn_position == null:
		# Tudo à vista (raro): pula esta vez em vez de brotar na cara do player.
		return
	var enemy := enemy_scene.instantiate() as Node3D
	# Filho do spawner: a arena fica organizada e dá para limpar tudo junto.
	add_child(enemy)
	enemy.global_position = spawn_position


## Sorteia pontos no círculo em volta do player até achar um que a câmera não vê.
## Com câmera em 3ª pessoa, na prática eles nascem atrás e dos lados.
func _find_offscreen_position(center: Vector3) -> Variant:
	var camera := get_viewport().get_camera_3d()
	for i in offscreen_attempts:
		var angle := randf() * TAU
		var point := Vector3(center.x + cos(angle) * spawn_radius, 0.0, center.z + sin(angle) * spawn_radius)
		# Testa o meio do corpo, não o pé, para não aparecer metade do porco.
		if camera == null or not camera.is_position_in_frustum(point + Vector3.UP * 0.5):
			return point
	return null
