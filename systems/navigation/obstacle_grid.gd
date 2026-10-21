class_name ObstacleGrid
extends Node
## "Mapa de bloqueios" do chão em células de cell_size metros (só X/Z).
##
## Por quê: os inimigos andam sem física (é o que segura 500 a ~80 FPS), então
## não enxergam muros, pilares e árvores. Aqui os obstáculos viram uma grade
## uma vez só, ao montar o mapa; durante o jogo, perguntar "está bloqueado?"
## é só olhar um dicionário.
##
## Uso: `ObstacleGrid.is_blocked(x, z)` (sem grade no mapa = nada bloqueado).
## Debug (só no editor): tecla G mostra as células bloqueadas em vermelho.

static var active: ObstacleGrid

@export var cell_size: float = 1.0
## Faixa de altura testada, acima do chão: o que fica só lá em cima (viga do
## torii) ou rente ao chão não bloqueia quem anda.
@export var probe_bottom: float = 0.2
@export var probe_top: float = 1.4
## Frames de física de espera antes de montar: o TerrainScatter espalha as
## árvores/pedras com call_deferred e a física precisa registrar os corpos.
@export var bake_delay_frames: int = 3

var _blocked: Dictionary = {}  # Vector2i -> true
var _frames_until_bake: int = 0
var _baked := false
var _debug_view: MultiMeshInstance3D


func _enter_tree() -> void:
	active = self


func _exit_tree() -> void:
	if active == self:
		active = null


func _ready() -> void:
	_frames_until_bake = bake_delay_frames


## Consulta direta à física só funciona com segurança dentro do passo de física.
func _physics_process(_delta: float) -> void:
	if _baked:
		return
	_frames_until_bake -= 1
	if _frames_until_bake <= 0:
		_bake()


static func is_blocked(x: float, z: float) -> bool:
	if active == null:
		return false
	return active._blocked.has(active.cell_of(x, z))


func is_cell_blocked(cell: Vector2i) -> bool:
	return _blocked.has(cell)


func cell_of(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / cell_size), floori(z / cell_size))


func blocked_count() -> int:
	return _blocked.size()


## Para cada obstáculo, só testa as células dentro da caixa dele (e não o mapa
## inteiro): poucos milhares de testes em vez de dezenas de milhares.
func _bake() -> void:
	_baked = true
	var started := Time.get_ticks_usec()
	var space := get_viewport().world_3d.direct_space_state
	var probe := BoxShape3D.new()
	probe.size = Vector3(cell_size * 0.9, probe_top - probe_bottom, cell_size * 0.9)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collide_with_areas = false
	if HeightTerrain.active:
		query.exclude = [HeightTerrain.active.get_rid()]

	var level := get_parent()
	var tested := {}
	for body in level.find_children("*", "StaticBody3D", true, false):
		if body == HeightTerrain.active:
			continue
		for shape_node in body.find_children("*", "CollisionShape3D", true, false):
			var cs := shape_node as CollisionShape3D
			if cs.shape == null or cs.disabled:
				continue
			var box := cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
			var from := cell_of(box.position.x, box.position.z)
			var to := cell_of(box.end.x, box.end.z)
			for cx in range(from.x, to.x + 1):
				for cz in range(from.y, to.y + 1):
					var cell := Vector2i(cx, cz)
					if tested.has(cell):
						continue
					tested[cell] = true
					var center := Vector2((cx + 0.5) * cell_size, (cz + 0.5) * cell_size)
					var ground := HeightTerrain.ground_height(center.x, center.y)
					var mid := ground + (probe_bottom + probe_top) * 0.5
					query.transform = Transform3D(Basis.IDENTITY, Vector3(center.x, mid, center.y))
					if not space.intersect_shape(query, 1).is_empty():
						_blocked[cell] = true
	print("[ObstacleGrid] %d células bloqueadas (%d testadas) em %.1f ms" % [
		_blocked.size(), tested.size(), (Time.get_ticks_usec() - started) / 1000.0])


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_toggle_debug_view()


## Um quadrado vermelho por célula bloqueada, num MultiMesh só (leve mesmo com milhares).
func _toggle_debug_view() -> void:
	if _debug_view:
		_debug_view.queue_free()
		_debug_view = null
		return
	var quad := PlaneMesh.new()
	quad.size = Vector2(cell_size, cell_size) * 0.9
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1, 0.1, 0.1, 0.55)
	material.no_depth_test = true
	quad.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = _blocked.size()
	var i := 0
	for cell: Vector2i in _blocked:
		var x := (cell.x + 0.5) * cell_size
		var z := (cell.y + 0.5) * cell_size
		var y := HeightTerrain.ground_height(x, z) + 0.05
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
		i += 1
	_debug_view = MultiMeshInstance3D.new()
	_debug_view.multimesh = multimesh
	_debug_view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_debug_view)
	print("[ObstacleGrid] debug: %d células" % _blocked.size())
