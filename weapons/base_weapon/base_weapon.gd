class_name BaseWeapon
extends Node3D
## Arma automática: a cada intervalo atira no inimigo mais perto dentro do alcance
## (ou no alvo da mira travada, se ele estiver no alcance).
## Os números vêm de um WeaponStats (.tres em data/weapons/) e as balas de um ObjectPool.

@export var stats: WeaponStats
@export var projectile_scene: PackedScene
## Balas criadas já no começo, guardadas na reserva.
@export var pool_initial_size: int = 30
## Altura de onde a bala sai, em relação ao pé do player.
@export var muzzle_height: float = 1.0
## Altura para onde mirar quando o alvo não diz a dele (BaseEnemy.aim_height).
@export var target_height: float = 0.45

var _time_until_fire: float = 0.0
var _pool: ObjectPool
var _locked_target: Node3D


## O pool é um Node (não Node3D): por isso as balas, filhas dele, NÃO herdam a
## posição do player e voam livres mesmo com o pool pendurado na arma.
func _ready() -> void:
	# Cópia própria: upgrades mexem nela sem alterar o .tres compartilhado.
	if stats:
		stats = stats.duplicate()
	if projectile_scene == null:
		push_warning("%s sem projectile_scene." % name)
		return
	_pool = ObjectPool.new()
	_pool.name = "ProjectilePool"
	_pool.scene = projectile_scene
	_pool.initial_size = pool_initial_size
	_pool.warm_up = true
	add_child(_pool)
	EventBus.lock_on_changed.connect(func(target: Node3D) -> void: _locked_target = target)


func _physics_process(delta: float) -> void:
	if stats == null or _pool == null:
		return
	_time_until_fire -= delta
	if _time_until_fire > 0.0:
		return
	var target := _choose_target()
	if target == null:
		return  # sem alvo: fica pronta e atira assim que algum entrar no alcance
	_time_until_fire = stats.fire_interval
	_fire_at(target)


## Mira travada manda, mas só dentro do alcance: fora dele, volta ao mais perto
## para o player não ficar indefeso enquanto foge do chefe.
func _choose_target() -> Node3D:
	if _locked_target and LockOn.is_valid_target(_locked_target):
		var range_sq := stats.fire_range * stats.fire_range
		if global_position.distance_squared_to(_locked_target.global_position) <= range_sq:
			return _locked_target
	return _find_nearest_enemy()


## Percorre os inimigos ativos e pega o mais perto. Compara distância ao quadrado
## (sem raiz quadrada), que é mais barato e dá o mesmo resultado.
## Com 500 inimigos e um tiro a cada 0,8s isso é barato; se pesar, dá para usar uma grade espacial.
func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance_sq := stats.fire_range * stats.fire_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance_sq := global_position.distance_squared_to((enemy as Node3D).global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = enemy
	return nearest


func _fire_at(target: Node3D) -> void:
	var from := global_position + Vector3.UP * muzzle_height
	var height := (target as BaseEnemy).aim_height if target is BaseEnemy else target_height
	var to := target.global_position + Vector3.UP * height
	var projectile := _pool.acquire() as Projectile
	# Tiro na mira travada atravessa a horda e só acerta o alvo.
	var only_target: Node = target if target == _locked_target else null
	projectile.launch(from, to - from, stats, only_target)
