@tool
class_name HeightTerrain
extends StaticBody3D
## Chão com relevo gerado por código: morros de ruído + áreas moldadas à mão
## (TerrainArea: plano, platô, rampa, lago). Gera a malha low-poly facetada, a
## colisão do player e uma grade de alturas.
##
## Inimigos não usam física: perguntam a altura do chão em ground_height(x, z),
## que só lê a grade (bem mais barato que raycast com centenas na tela).
## @tool: o relevo aparece no editor; mudou algo e não atualizou → botão "Regerar".

## Grade, malha e colisão prontas (o TerrainScatter espera por isso).
signal rebuilt

## Terreno ativo da partida (um por mapa). Sem terreno, o chão é y = 0.
static var active: HeightTerrain

## Tamanho total no plano X/Z (metros); a origem do nó fica no centro.
@export var size := Vector2(160, 120):
	set(value):
		size = value
		_queue_rebuild()
## Lado de cada quadradinho da malha. Maior = mais "low-poly" e mais leve.
@export var cell_size: float = 2.0:
	set(value):
		cell_size = maxf(value, 0.25)
		_queue_rebuild()
## Altura máxima dos morros gerados pelo ruído.
@export var hill_height: float = 4.0:
	set(value):
		hill_height = value
		_queue_rebuild()
@export var noise: FastNoiseLite:
	set(value):
		if noise and noise.changed.is_connected(_queue_rebuild):
			noise.changed.disconnect(_queue_rebuild)
		noise = value
		if noise:
			noise.changed.connect(_queue_rebuild)
		_queue_rebuild()
## Áreas com altura definida à mão, aplicadas em ordem (a última vence).
@export var areas: Array[TerrainArea] = []:
	set(value):
		areas = value
		_queue_rebuild()

@export_group("Cores")
@export var grass_color := Color(0.3, 0.6, 0.24)
@export var high_grass_color := Color(0.18, 0.43, 0.2)
@export var rock_color := Color(0.52, 0.5, 0.47)
@export var mud_color := Color(0.42, 0.37, 0.28)
## Inclinação a partir da qual a face vira pedra (normal.y menor que isso).
@export_range(0.0, 1.0) var rock_slope: float = 0.72

@export_tool_button("Regerar terreno") var _rebuild_button: Callable = rebuild

var _heights := PackedFloat32Array()
var _columns: int = 0
var _rows: int = 0
var _rebuild_queued := false
var _mesh_instance: MeshInstance3D
var _collision: CollisionShape3D


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		active = self


func _exit_tree() -> void:
	if active == self:
		active = null


func _ready() -> void:
	rebuild()


## Altura do chão em (x, z) do mundo. Fora do terreno (ou sem terreno) = 0.
static func ground_height(x: float, z: float) -> float:
	if active == null:
		return 0.0
	return active.height_at(x, z)


## Altura em coordenadas do mundo, igual à da malha (mesma divisão dos triângulos).
func height_at(x: float, z: float) -> float:
	if _heights.is_empty():
		return global_position.y
	var gx := (x - global_position.x + size.x * 0.5) / cell_size
	var gz := (z - global_position.z + size.y * 0.5) / cell_size
	if gx < 0.0 or gz < 0.0 or gx > _columns or gz > _rows:
		return 0.0
	var i := mini(int(gx), _columns - 1)
	var j := mini(int(gz), _rows - 1)
	var fx := gx - i
	var fz := gz - j
	var h00 := _heights[j * (_columns + 1) + i]
	var h10 := _heights[j * (_columns + 1) + i + 1]
	var h01 := _heights[(j + 1) * (_columns + 1) + i]
	var h11 := _heights[(j + 1) * (_columns + 1) + i + 1]
	# Cada quadrado é dividido na diagonal (0,0)-(1,1), como na malha.
	var h: float
	if fx > fz:
		h = h00 + fx * (h10 - h00) + fz * (h11 - h10)
	else:
		h = h00 + fz * (h01 - h00) + fx * (h11 - h01)
	return h + global_position.y


## Altura "de projeto" num ponto local (ruído + áreas), usada para montar a grade.
func _design_height(point: Vector2) -> float:
	var h := 0.0
	if noise:
		# Só a parte positiva do ruído vira morro: sobra planície entre eles.
		h = maxf(noise.get_noise_2d(point.x, point.y), 0.0) * 2.0 * hill_height
	for area in areas:
		if area:
			h = lerpf(h, area.height_at(point), area.weight_at(point))
	return h


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	rebuild.call_deferred()


func rebuild() -> void:
	_rebuild_queued = false
	_columns = maxi(int(ceil(size.x / cell_size)), 1)
	_rows = maxi(int(ceil(size.y / cell_size)), 1)
	_heights.resize((_columns + 1) * (_rows + 1))
	var origin := -size * 0.5
	for j in _rows + 1:
		for i in _columns + 1:
			_heights[j * (_columns + 1) + i] = _design_height(origin + Vector2(i, j) * cell_size)
	_build_mesh(origin)
	rebuilt.emit()


func _build_mesh(origin: Vector2) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in _rows:
		for i in _columns:
			var p00 := _vertex(origin, i, j)
			var p10 := _vertex(origin, i + 1, j)
			var p01 := _vertex(origin, i, j + 1)
			var p11 := _vertex(origin, i + 1, j + 1)
			# Mesma diagonal de height_at(). O Godot considera frente o sentido horário.
			_add_face(st, p00, p10, p11)
			_add_face(st, p00, p11, p01)
	var mesh := st.commit()

	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "Mesh"
		add_child(_mesh_instance)
		_collision = CollisionShape3D.new()
		_collision.name = "Collision"
		add_child(_collision)
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = _make_material()
	_collision.shape = mesh.create_trimesh_shape()


func _vertex(origin: Vector2, i: int, j: int) -> Vector3:
	var p := origin + Vector2(i, j) * cell_size
	return Vector3(p.x, _heights[j * (_columns + 1) + i], p.y)


## Cada triângulo com a própria normal e cor: o visual facetado do low-poly.
func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	var color := _face_color(normal, (a.y + b.y + c.y) / 3.0, a)
	for v in [a, b, c]:
		st.set_normal(normal)
		st.set_color(color)
		st.add_vertex(v)


func _face_color(normal: Vector3, mid_height: float, any_vertex: Vector3) -> Color:
	var color: Color
	if normal.y < rock_slope:
		color = rock_color
	elif mid_height < -0.2:
		color = mud_color
	else:
		var t := clampf(mid_height / maxf(hill_height, 0.01), 0.0, 1.0)
		color = grass_color.lerp(high_grass_color, t)
	# Variação leve por face, para o chão não parecer liso de uma cor só.
	var jitter := (hash(Vector2i(int(any_vertex.x * 7.0), int(any_vertex.z * 13.0))) % 1000) / 1000.0
	return color.darkened(jitter * 0.08)


func _make_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	return material
