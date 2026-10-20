@tool
class_name TerrainScatter
extends Node3D
## Espalha cópias de uma cena (árvores, pedras) ou de uma malha (tufos de grama)
## em cima do HeightTerrain pai, com semente fixa: o mesmo mapa sai sempre igual.
## As cópias são criadas ao abrir a cena (não ficam salvas no .tscn), então
## mudar quantidade/semente no Inspetor redistribui tudo.
##
## Com `mesh` usa MultiMeshInstance3D: milhares de cópias num desenho só, sem
## colisão (ideal para grama). Com `scene` instancia de verdade (com colisão).

@export var scene: PackedScene:
	set(value):
		scene = value
		_queue_scatter()
@export var mesh: Mesh:
	set(value):
		mesh = value
		_queue_scatter()
@export var count: int = 50:
	set(value):
		count = maxi(value, 0)
		_queue_scatter()
@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_queue_scatter()
## Onde espalhar, em coordenadas do mundo (X/Z).
@export var area := Rect2(-10, -10, 20, 20):
	set(value):
		area = value
		_queue_scatter()
## Retângulos do mundo (X/Z) onde não pode nascer nada: caminho, lago, rampa.
@export var avoid: Array[Rect2] = []:
	set(value):
		avoid = value
		_queue_scatter()
## Não coloca em encosta mais íngreme que isso (graus).
@export_range(0.0, 90.0) var max_slope_deg: float = 25.0
## Não coloca abaixo dessa altura (fundo do lago).
@export var min_height: float = -0.1
@export var min_scale: float = 0.8
@export var max_scale: float = 1.25

@export_tool_button("Espalhar de novo") var _scatter_button: Callable = scatter

var _queued := false
var _container: Node3D


func _ready() -> void:
	# Os filhos ficam prontos antes do pai: espera o terreno montar a grade.
	var terrain := get_parent() as HeightTerrain
	if terrain:
		terrain.rebuilt.connect(_queue_scatter)
	_queue_scatter()


func _queue_scatter() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	scatter.call_deferred()


func scatter() -> void:
	_queued = false
	var terrain := get_parent() as HeightTerrain
	if terrain == null:
		push_warning("%s precisa ser filho de um HeightTerrain." % name)
		return
	if _container:
		_container.free()
	_container = Node3D.new()
	_container.name = "Scattered"
	add_child(_container)

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var transforms: Array[Transform3D] = []
	var max_tries := count * 10
	var tries := 0
	while transforms.size() < count and tries < max_tries:
		tries += 1
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if _is_avoided(p):
			continue
		var h := terrain.height_at(p.x, p.y)
		if h < min_height or _slope_deg(terrain, p) > max_slope_deg:
			continue
		var s := rng.randf_range(min_scale, max_scale)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s)
		transforms.append(Transform3D(basis, Vector3(p.x, h, p.y)))

	if mesh:
		_build_multimesh(transforms)
	elif scene:
		for t in transforms:
			var node := scene.instantiate() as Node3D
			_container.add_child(node)
			node.global_transform = t


func _build_multimesh(transforms: Array[Transform3D]) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, global_transform.affine_inverse() * transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_container.add_child(instance)


func _is_avoided(p: Vector2) -> bool:
	for rect in avoid:
		if rect.has_point(p):
			return true
	return false


## Inclinação pela diferença de altura entre pontos vizinhos.
func _slope_deg(terrain: HeightTerrain, p: Vector2) -> float:
	var d := 1.0
	var dx := terrain.height_at(p.x + d, p.y) - terrain.height_at(p.x - d, p.y)
	var dz := terrain.height_at(p.x, p.y + d) - terrain.height_at(p.x, p.y - d)
	return rad_to_deg(atan(Vector2(dx, dz).length() / (2.0 * d)))
