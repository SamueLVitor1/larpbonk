class_name BaseEnemy
extends Node3D
## Molde de todo inimigo. Não usa física (Node3D, não CharacterBody3D): com
## centenas na tela, mover por código é bem mais barato.
## Os números vêm de um EnemyStats (.tres em data/enemies/).

@export var stats: EnemyStats
## Para de andar quando está mais perto que isso (evita tremer em cima do player).
@export var stop_distance: float = 0.5
## Quanto tempo o inimigo fica branco ao tomar dano (segundos).
@export var hit_flash_duration: float = 0.08
## Altura do meio do corpo (em relação ao pé): para onde as balas e a mira travada apontam.
@export var aim_height: float = 0.45
## Raio do corpo no chão: olha esse tanto à frente para não enfiar o focinho no
## muro (ObstacleGrid). Porco ~0,5; chefes maiores.
@export var body_radius: float = 0.5
## Velocidade máxima (m/s) do empurrão para longe dos vizinhos (HordeSeparation).
@export var separation_speed: float = 2.5
## Sombra do sol. Desligada nos inimigos de horda: cada sombra redesenha o
## inimigo em todas as camadas (cascatas) do sol; com centenas na tela, isso
## pesava mais que todo o resto (65 ms/frame com o jogo pausado, só desenho).
## Ligada em quem é único, como chefes.
@export var cast_shadows: bool = false

## Um material só, compartilhado por todos os inimigos: piscar é só ligar/desligar
## o overlay em cada malha, sem criar nada novo a cada acerto.
static var _flash_material: StandardMaterial3D

var target: Node3D
var _move_speed: float = 3.0
var _meshes: Array[MeshInstance3D] = []
var _flash_time_left: float = 0.0
## Empurrão para longe dos vizinhos (direção × força 0–1), escrito pelo HordeSeparation.
var separation := Vector3.ZERO

@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	_apply_stats()
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	# Busca as malhas uma vez só (o modelo do .glb pode ter várias).
	for node in $Model.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Vindo de um pool, só entra no grupo ao sair da reserva (on_pool_acquire);
	# senão os guardados contariam no limite do spawner e na tecla K.
	if not has_meta(&"object_pool"):
		add_to_group("enemies")


## Saiu da reserva: volta com vida cheia e passa a contar como inimigo ativo.
func on_pool_acquire() -> void:
	health.reset()
	add_to_group("enemies")


## Voltou para a reserva: deixa de contar como inimigo.
func on_pool_release() -> void:
	remove_from_group("enemies")
	separation = Vector3.ZERO
	_set_flash(false)


## Anda reto até o player, só no plano XZ, e vira o corpo para ele.
## A altura vem do terreno (sem física): sobe morro e desce vale grudado no chão.
## O modelo olha para +Z, por isso atan2(x, z).
func _physics_process(delta: float) -> void:
	# Contador simples em vez de Tween/Timer: com centenas de inimigos é mais barato.
	if _flash_time_left > 0.0:
		_flash_time_left -= delta
		if _flash_time_left <= 0.0:
			_set_flash(false)
	if target == null:
		# Busca "preguiçosa": não depende da ordem em que player e inimigo entram na cena.
		target = get_tree().get_first_node_in_group("player") as Node3D
		if target == null:
			return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var direction := to_target.normalized()
	# Setinha do campo de fluxo (dá a volta nos muros); sem campo, vai reto.
	var path := FlowField.direction_at(global_position.x, global_position.z, direction)
	rotation.y = atan2(path.x, path.z)
	# Colado no player para de avançar, mas continua sendo empurrado pelos
	# vizinhos: senão a roda em volta do player vira um bolo de novo.
	if to_target.length() <= stop_distance:
		path = Vector3.ZERO
	var velocity := path * _move_speed + separation * separation_speed
	var step := _slide(velocity * delta)
	if step == Vector3.ZERO:
		return
	var next := global_position + step
	next.y = HeightTerrain.ground_height(next.x, next.z)
	global_position = next


## Desvia de obstáculos sem física: tenta o passo direto; se bater, tenta só no
## X ou só no Z (na velocidade cheia), o que faz o inimigo escorregar ao longo
## do muro. Encurralado nos dois = fica parado neste frame em vez de atravessar.
func _slide(step: Vector3) -> Vector3:
	# Já está numa célula bloqueada (nasceu ou foi empurrado para dentro): deixa sair.
	if ObstacleGrid.is_blocked(global_position.x, global_position.z):
		return step
	var length := step.length()
	for candidate: Vector3 in [
		step,
		Vector3(signf(step.x) * length, 0.0, 0.0),
		Vector3(0.0, 0.0, signf(step.z) * length),
	]:
		if candidate == Vector3.ZERO:
			continue
		var ahead := global_position + candidate + candidate.normalized() * body_radius
		if not ObstacleGrid.is_blocked(ahead.x, ahead.z):
			return candidate
	return Vector3.ZERO


## Passa os números do .tres para os componentes. Os filhos rodam _ready()
## antes do pai, por isso o reset() aqui: a vida já tinha sido iniciada com o padrão.
func _apply_stats() -> void:
	if stats == null:
		push_warning("%s sem EnemyStats, usando valores padrão." % name)
		return
	health.max_health = stats.max_health
	health.reset()
	hitbox.damage = stats.contact_damage
	_move_speed = stats.move_speed


func _on_damaged(amount: float) -> void:
	_flash_time_left = hit_flash_duration
	_set_flash(true)
	EventBus.enemy_damaged.emit(global_position + Vector3.UP * 1.0, amount)


func _set_flash(on: bool) -> void:
	if _flash_material == null:
		_flash_material = StandardMaterial3D.new()
		_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_material.albedo_color = Color(1, 1, 1, 0.85)
	for mesh in _meshes:
		mesh.material_overlay = _flash_material if on else null


func _on_died() -> void:
	EventBus.enemy_died.emit(global_position, stats.xp_value if stats else 0.0)
	# Deferred: a morte acontece no meio da checagem de colisão da hitbox,
	# e desligar áreas de colisão nesse momento dá erro no Godot.
	_despawn.call_deferred()


func _despawn() -> void:
	# Volta para a reserva se veio de um pool; senão (ex.: porco fixo da arena) apaga.
	ObjectPool.release_or_free(self)
