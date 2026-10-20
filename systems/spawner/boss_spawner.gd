class_name BossSpawner
extends Node
## Solta um chefe uma única vez quando o cronômetro da partida chega em spawn_time.
## Separado do EnemySpawner: a horda usa pool e sai o tempo todo; o chefe é único
## e cada um tem sua hora (no futuro, um BossSpawner por chefe).
## É Node (não Node3D) pelo mesmo motivo do pool: o chefe filho não herda posição.

@export var boss_scene: PackedScene
## Segundos de partida até o chefe aparecer.
@export var spawn_time: int = 30
## Usado para achar um ponto válido (fora da câmera, dentro do mapa, no chão).
@export var enemy_spawner: EnemySpawner

var _spawned := false


func _ready() -> void:
	if boss_scene == null or enemy_spawner == null:
		push_warning("BossSpawner sem boss_scene ou enemy_spawner.")
		return
	EventBus.run_time_changed.connect(_on_run_time_changed)


## O cronômetro vem do EventBus (um aviso por segundo), igual à HUD.
func _on_run_time_changed(seconds: int) -> void:
	if _spawned or seconds < spawn_time:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var point: Variant = enemy_spawner.find_spawn_position(player.global_position)
	if point == null:
		return  # tudo à vista agora: tenta de novo no próximo segundo
	_spawned = true
	var boss := boss_scene.instantiate() as Node3D
	add_child(boss)
	boss.global_position = point
