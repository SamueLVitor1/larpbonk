class_name ObjectPool
extends Node
## Reserva de objetos reaproveitáveis: em vez de instantiate()/queue_free()
## o tempo todo, os objetos são desligados e religados.
## Genérico: serve para inimigos, projéteis, gemas de XP...
##
## Os objetos ficam como filhos do pool a vida toda. Para reagir, o objeto pode ter:
##   on_pool_acquire()  -> chamado ao sair da reserva (ex.: resetar vida)
##   on_pool_release()  -> chamado ao voltar para a reserva

@export var scene: PackedScene
## Quantos criar já no começo, para não engasgar na primeira onda.
@export var initial_size: int = 50

var _available: Array[Node] = []


func _ready() -> void:
	for i in initial_size:
		_available.append(_create())


## Pega um objeto da reserva (ou cria um, se ela estiver vazia) e liga.
func acquire() -> Node:
	var node: Node = _available.pop_back() if not _available.is_empty() else _create()
	_set_active(node, true)
	if node.has_method("on_pool_acquire"):
		node.on_pool_acquire()
	return node


## Desliga o objeto e devolve para a reserva.
func release(node: Node) -> void:
	if node in _available:
		return  # já estava na reserva (ex.: morreu duas vezes no mesmo frame)
	if node.has_method("on_pool_release"):
		node.on_pool_release()
	_set_active(node, false)
	_available.append(node)


## Devolve um objeto para o pool de onde ele veio; se não veio de um pool, apaga.
## Assim quem chama não precisa saber se o objeto é reaproveitado ou não.
static func release_or_free(node: Node) -> void:
	var pool := node.get_meta(&"object_pool", null) as ObjectPool
	if pool:
		pool.release(node)
	else:
		node.queue_free()


func available_count() -> int:
	return _available.size()


func _create() -> Node:
	var node := scene.instantiate()
	node.set_meta(&"object_pool", self)
	_set_active(node, false)
	add_child(node)
	return node


## PROCESS_MODE_DISABLED para scripts e também tira as áreas de colisão da física.
func _set_active(node: Node, active: bool) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if node is Node3D:
		node.visible = active
