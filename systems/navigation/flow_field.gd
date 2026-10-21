class_name FlowField
extends Node
## "Setinhas" no chão apontando o caminho até o player, desviando dos obstáculos.
##
## Por quê: só deslizar no muro (BaseEnemy._slide) não ensina o inimigo a dar a
## volta; atrás de um muro comprido ele trava num canto. Aqui, de tempos em
## tempos, uma busca em largura (BFS) parte da célula do player e calcula, de
## uma vez, a distância de TODAS as células por perto até ele. Cada célula guarda
## a direção do vizinho mais perto do player: o inimigo só lê a setinha da
## célula onde está. Custo fixo por atualização, não importa se são 5 ou 500.
##
## Cobre uma janela de `radius` metros em volta do player (não o mapa inteiro),
## para a BFS ficar barata; fora dela o inimigo anda reto até entrar.
## Usa as células do ObstacleGrid (mesmo cell_size). Sem grade = sem campo.
## Debug (só no editor): tecla F mostra as setinhas.

@warning_ignore_start("integer_division")  # índice / lado = linha da grade, de propósito

static var active: FlowField

## Metros em volta do player cobertos pelo campo.
@export var radius: float = 40.0
## Segundos entre recálculos (o player anda pouco nesse tempo).
@export var update_interval: float = 0.25
## Player numa célula bloqueada: até quantas células em volta procurar chão livre.
@export var max_start_ring: int = 6

const UNREACHED := -1
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var _size: int = 0  # lado da janela, em células
var _origin := Vector2i.ZERO  # célula do canto da janela
var _distance := PackedInt32Array()
var _direction := PackedVector2Array()
var _player: Node3D
var _time_until_update: float = 0.0
var _debug_view: MultiMeshInstance3D


func _enter_tree() -> void:
	active = self


func _exit_tree() -> void:
	if active == self:
		active = null


func _physics_process(delta: float) -> void:
	_time_until_update -= delta
	if _time_until_update > 0.0:
		return
	_time_until_update = update_interval
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player and ObstacleGrid.active:
		_rebuild(_player.global_position)
		if _debug_view:
			_refresh_debug_view()


## Direção (no plano X/Z, normalizada) para seguir em (x, z). Sem campo, fora
## da janela, ou já na célula do player: devolve `fallback` (andar reto).
static func direction_at(x: float, z: float, fallback: Vector3) -> Vector3:
	if active == null or active._size == 0:
		return fallback
	var dir := active._direction_of(ObstacleGrid.active.cell_of(x, z))
	if dir == Vector2.ZERO:
		return fallback
	return Vector3(dir.x, 0.0, dir.y)


func _direction_of(cell: Vector2i) -> Vector2:
	var local := cell - _origin
	if local.x < 0 or local.y < 0 or local.x >= _size or local.y >= _size:
		return Vector2.ZERO
	return _direction[local.y * _size + local.x]


func _blocked(cell: Vector2i) -> bool:
	return ObstacleGrid.active.is_cell_blocked(cell)


## BFS com 4 vizinhos a partir do player; depois, para cada célula alcançada,
## escolhe o vizinho (8 direções) com menor distância. Diagonal só se as duas
## laterais estiverem livres, para não "cortar a quina" de um muro.
func _rebuild(target: Vector3) -> void:
	var grid := ObstacleGrid.active
	var cells := ceili(radius / grid.cell_size)
	_size = cells * 2 + 1
	var center := grid.cell_of(target.x, target.z)
	_origin = center - Vector2i(cells, cells)
	var total := _size * _size
	_distance.resize(total)
	_distance.fill(UNREACHED)
	_direction.resize(total)
	_direction.fill(Vector2.ZERO)

	var queue := PackedInt32Array()
	queue.resize(total)
	var head := 0
	var tail := 0
	# Ponto de partida: a célula do player. Se ela estiver bloqueada (player em
	# cima de muro, colado num pilar), parte das células livres mais próximas;
	# senão a busca não sai do lugar e a horda toda se amontoa num ponto só.
	for start in _start_cells(cells):
		_distance[start] = 0
		queue[tail] = start
		tail += 1
	while head < tail:
		var index := queue[head]
		head += 1
		var x := index % _size
		var y := index / _size
		var next_distance := _distance[index] + 1
		for i in 4:
			var nx := x + NEIGHBORS[i].x
			var ny := y + NEIGHBORS[i].y
			if nx < 0 or ny < 0 or nx >= _size or ny >= _size:
				continue
			var n := ny * _size + nx
			if _distance[n] != UNREACHED:
				continue
			if _blocked(_origin + Vector2i(nx, ny)):
				continue
			_distance[n] = next_distance
			queue[tail] = n
			tail += 1

	for index in tail:
		var d := _distance[index]
		if d == 0:
			continue  # célula do player: o inimigo vai reto
		var x := index % _size
		var y := index / _size
		var best := d
		var best_offset := Vector2i.ZERO
		for offset in NEIGHBORS:
			var nx := x + offset.x
			var ny := y + offset.y
			if nx < 0 or ny < 0 or nx >= _size or ny >= _size:
				continue
			var nd := _distance[ny * _size + nx]
			if nd == UNREACHED or nd >= best:
				continue
			if offset.x != 0 and offset.y != 0:
				if _distance[y * _size + nx] == UNREACHED or _distance[ny * _size + x] == UNREACHED:
					continue
			best = nd
			best_offset = offset
		if best_offset != Vector2i.ZERO:
			_direction[index] = Vector2(best_offset).normalized()


## Índices de onde a BFS começa: a célula central, ou o anel de células livres
## mais próximo dela (até `max_start_ring` células de distância).
func _start_cells(cells: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	if not _blocked(_origin + Vector2i(cells, cells)):
		result.append(cells * _size + cells)
		return result
	for ring in range(1, max_start_ring + 1):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue  # só a borda do anel
				var local := Vector2i(cells + dx, cells + dy)
				if not _blocked(_origin + local):
					result.append(local.y * _size + local.x)
		if not result.is_empty():
			return result
	result.append(cells * _size + cells)  # cercado de bloqueio: parte do centro mesmo
	return result


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if _debug_view:
			_debug_view.queue_free()
			_debug_view = null
		else:
			_refresh_debug_view()


## Uma setinha (triângulo achatado) por célula alcançada, num MultiMesh só.
func _refresh_debug_view() -> void:
	if _debug_view == null:
		var arrow := PrismMesh.new()
		arrow.size = Vector3(0.35, 0.6, 0.02)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.3, 0.9, 1.0)
		material.no_depth_test = true
		arrow.material = material
		_debug_view = MultiMeshInstance3D.new()
		_debug_view.multimesh = MultiMesh.new()
		_debug_view.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		_debug_view.multimesh.mesh = arrow
		_debug_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_debug_view)
	var cell_size := ObstacleGrid.active.cell_size if ObstacleGrid.active else 1.0
	var transforms: Array[Transform3D] = []
	for index in _direction.size():
		var dir := _direction[index]
		if dir == Vector2.ZERO:
			continue
		var cell := _origin + Vector2i(index % _size, index / _size)
		var x := (cell.x + 0.5) * cell_size
		var z := (cell.y + 0.5) * cell_size
		var y := HeightTerrain.ground_height(x, z) + 0.08
		# Prisma deitado no chão, com a ponta (eixo +Y da malha) apontando para dir.
		var basis := Basis(Vector3.RIGHT, PI / 2.0).rotated(Vector3.UP, atan2(dir.x, dir.y))
		transforms.append(Transform3D(basis, Vector3(x, y, z)))
	var multimesh := _debug_view.multimesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
