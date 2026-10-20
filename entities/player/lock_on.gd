class_name LockOn
extends Node
## Travar mira (tecla R): escolhe o chefe mais perto e avisa pelo EventBus.
## R de novo destrava; destrava sozinho se o alvo morrer ou sumir.
## Só guarda o alvo: a arma e a HUD escutam o sinal e fazem a parte delas.
## A câmera não é travada de propósito: o player continua mirando livre com o mouse.

## Só inimigos neste grupo podem ser travados.
@export var lockable_group: StringName = &"bosses"

var target: Node3D


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("lock_on"):
		return
	if target:
		_set_target(null)
	else:
		_set_target(_find_nearest_lockable())


## Checa todo frame: o alvo pode morrer no meio de uma rajada.
func _process(_delta: float) -> void:
	if target and not is_valid_target(target):
		_set_target(null)


## Vivo e em jogo. Inimigo de pool que "morre" sai do grupo "enemies";
## o chefe (sem pool) é apagado, por isso o is_instance_valid.
static func is_valid_target(node: Node3D) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and node.is_in_group("enemies")


func _find_nearest_lockable() -> Node3D:
	var player := get_parent() as Node3D
	var nearest: Node3D = null
	var nearest_distance_sq := INF
	for node in get_tree().get_nodes_in_group(lockable_group):
		var candidate := node as Node3D
		if not is_valid_target(candidate):
			continue
		var distance_sq := player.global_position.distance_squared_to(candidate.global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = candidate
	return nearest


func _set_target(new_target: Node3D) -> void:
	if new_target == target:
		return
	target = new_target
	EventBus.lock_on_changed.emit(target)
