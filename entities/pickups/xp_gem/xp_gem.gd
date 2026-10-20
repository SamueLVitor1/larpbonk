class_name XpGem
extends Node3D
## Gema de XP deixada por inimigos. Fica girando no chão; quando o player chega
## dentro do raio de coleta dele, é puxada (acelerando) até ser coletada.
## Sem física: só distância, para aguentar centenas. Vem de um ObjectPool.

## Graus por segundo.
@export var spin_speed: float = 90.0
## Aceleração do "ímã" (m/s²) depois que a gema é puxada.
@export var attract_acceleration: float = 40.0
## Distância em que a gema conta como coletada.
@export var collect_distance: float = 0.6
## Altura (em relação ao pé do player) para onde a gema voa.
@export var target_height: float = 0.8

var xp_value: float = 1.0
var _player: Player
var _attracted := false
var _speed: float = 0.0


## Chamado por quem solta a gema, logo depois de pegar do pool.
func drop(at: Vector3, value: float) -> void:
	global_position = at
	xp_value = value
	_attracted = false
	_speed = 0.0


func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed) * delta)

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return

	var target := _player.global_position + Vector3.UP * target_height
	var to_target := target - global_position
	var distance := to_target.length()

	# Uma vez puxada, não solta mais (mesmo se o player correr para longe).
	if not _attracted:
		if distance > _player.pickup_radius:
			return
		_attracted = true

	if distance <= collect_distance:
		_collect()
		return
	_speed += attract_acceleration * delta
	# min(): não passar do alvo num frame só.
	global_position += to_target / distance * minf(_speed * delta, distance)


func _collect() -> void:
	EventBus.xp_collected.emit(xp_value)
	ObjectPool.release_or_free(self)
