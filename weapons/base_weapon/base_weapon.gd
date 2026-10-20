class_name BaseWeapon
extends Node3D
## Arma automática: a cada intervalo atira no inimigo mais perto dentro do alcance.
## Fica como filha do player; as balas vão para a cena principal, senão
## andariam junto com o player.

@export var projectile_scene: PackedScene
@export var fire_interval: float = 0.8
## Só atira em inimigos até essa distância (metros).
@export var fire_range: float = 15.0
## Altura de onde a bala sai, em relação ao pé do player.
@export var muzzle_height: float = 1.0
## Altura do meio do corpo do inimigo, para onde mirar.
@export var target_height: float = 0.45

var _time_until_fire: float = 0.0


func _physics_process(delta: float) -> void:
	_time_until_fire -= delta
	if _time_until_fire > 0.0:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return  # sem alvo: fica pronta e atira assim que algum entrar no alcance
	_time_until_fire = fire_interval
	_fire_at(target)


## Percorre os inimigos ativos e pega o mais perto. Compara distância ao quadrado
## (sem raiz quadrada), que é mais barato e dá o mesmo resultado.
## Com 500 inimigos e um tiro a cada 0,8s isso é barato; se pesar, dá para usar uma grade espacial.
func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance_sq := fire_range * fire_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance_sq := global_position.distance_squared_to((enemy as Node3D).global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = enemy
	return nearest


func _fire_at(target: Node3D) -> void:
	if projectile_scene == null:
		return
	var from := global_position + Vector3.UP * muzzle_height
	var to := target.global_position + Vector3.UP * target_height
	var projectile := projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)
	projectile.launch(from, to - from)
